#!/usr/bin/env python3
"""
Load Balancer testing script
Tests ALB functionality, health checks, and traffic distribution
"""

import requests
import json
import time
import sys
import argparse
from typing import Dict, List
import concurrent.futures
import statistics
from collections import Counter

class LoadBalancerTester:
    def __init__(self, alb_dns_name: str):
        self.base_url = f"http://{alb_dns_name}"
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'LoadBalancer-Tester/1.0'
        })
    
    def test_basic_connectivity(self) -> Dict:
        """Test basic connectivity to the load balancer"""
        print("🔗 Testing basic ALB connectivity...")
        
        try:
            start_time = time.time()
            response = self.session.get(self.base_url, timeout=30)
            end_time = time.time()
            
            return {
                'test': 'basic_connectivity',
                'status': 'PASS' if response.status_code == 200 else 'FAIL',
                'status_code': response.status_code,
                'response_time': end_time - start_time,
                'content_length': len(response.content),
                'headers': dict(response.headers)
            }
        except Exception as e:
            return {
                'test': 'basic_connectivity',
                'status': 'FAIL',
                'error': str(e)
            }
    
    def test_health_checks(self) -> Dict:
        """Test health check endpoint"""
        print("🏥 Testing health check endpoint...")
        
        health_results = []
        
        # Test health endpoint multiple times
        for i in range(5):
            try:
                start_time = time.time()
                response = self.session.get(f"{self.base_url}/health", timeout=10)
                end_time = time.time()
                
                if response.status_code == 200:
                    try:
                        data = response.json()
                    except:
                        data = {}
                else:
                    data = {}
                
                health_results.append({
                    'attempt': i + 1,
                    'status_code': response.status_code,
                    'response_time': end_time - start_time,
                    'healthy': response.status_code == 200 and data.get('status') == 'healthy',
                    'instance_id': data.get('instance_id', 'unknown')
                })
                
                time.sleep(1)  # Wait between checks
                
            except Exception as e:
                health_results.append({
                    'attempt': i + 1,
                    'error': str(e),
                    'healthy': False
                })
        
        healthy_checks = sum(1 for r in health_results if r.get('healthy', False))
        avg_response_time = statistics.mean([r.get('response_time', 0) for r in health_results if 'response_time' in r])
        
        return {
            'test': 'health_checks',
            'status': 'PASS' if healthy_checks >= 4 else 'PARTIAL' if healthy_checks > 0 else 'FAIL',
            'total_checks': len(health_results),
            'healthy_checks': healthy_checks,
            'average_response_time': avg_response_time,
            'results': health_results
        }
    
    def test_load_distribution(self, num_requests: int = 100) -> Dict:
        """Test traffic distribution across instances"""
        print(f"⚖️ Testing load distribution with {num_requests} requests...")
        
        instance_responses = []
        response_times = []
        status_codes = Counter()
        
        def make_request():
            try:
                start_time = time.time()
                response = self.session.get(f"{self.base_url}/api/instance-info", timeout=10)
                end_time = time.time()
                
                response_time = end_time - start_time
                response_times.append(response_time)
                status_codes[response.status_code] += 1
                
                if response.status_code == 200:
                    try:
                        data = response.json()
                        return {
                            'instance_id': data.get('instance_id', 'unknown'),
                            'availability_zone': data.get('availability_zone', 'unknown'),
                            'private_ip': data.get('private_ip', 'unknown'),
                            'response_time': response_time,
                            'status_code': response.status_code
                        }
                    except:
                        return {
                            'instance_id': 'parse_error',
                            'response_time': response_time,
                            'status_code': response.status_code
                        }
                else:
                    return {
                        'instance_id': 'error',
                        'response_time': response_time,
                        'status_code': response.status_code
                    }
            except Exception as e:
                return {
                    'instance_id': 'exception',
                    'error': str(e),
                    'response_time': 0,
                    'status_code': 0
                }
        
        # Use ThreadPoolExecutor for concurrent requests
        with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
            futures = [executor.submit(make_request) for _ in range(num_requests)]
            
            for future in concurrent.futures.as_completed(futures):
                result = future.result()
                instance_responses.append(result)
        
        # Analyze distribution
        instance_counts = Counter([r['instance_id'] for r in instance_responses])
        az_counts = Counter([r.get('availability_zone', 'unknown') for r in instance_responses])
        
        # Calculate distribution metrics
        successful_requests = sum(1 for r in instance_responses if r['status_code'] == 200)
        unique_instances = len([k for k in instance_counts.keys() if k not in ['unknown', 'error', 'exception', 'parse_error']])
        
        # Calculate distribution evenness (coefficient of variation)
        if unique_instances > 1:
            valid_counts = [count for instance, count in instance_counts.items() 
                          if instance not in ['unknown', 'error', 'exception', 'parse_error']]
            if valid_counts:
                mean_requests = statistics.mean(valid_counts)
                std_requests = statistics.stdev(valid_counts) if len(valid_counts) > 1 else 0
                distribution_cv = (std_requests / mean_requests) * 100 if mean_requests > 0 else 0
            else:
                distribution_cv = 100
        else:
            distribution_cv = 0
        
        # Response time statistics
        if response_times:
            avg_response_time = statistics.mean(response_times)
            min_response_time = min(response_times)
            max_response_time = max(response_times)
            p95_response_time = sorted(response_times)[int(len(response_times) * 0.95)]
        else:
            avg_response_time = min_response_time = max_response_time = p95_response_time = 0
        
        return {
            'test': 'load_distribution',
            'status': 'PASS' if unique_instances > 1 and successful_requests > num_requests * 0.9 else 'PARTIAL' if successful_requests > 0 else 'FAIL',
            'total_requests': num_requests,
            'successful_requests': successful_requests,
            'unique_instances': unique_instances,
            'instance_distribution': dict(instance_counts),
            'az_distribution': dict(az_counts),
            'distribution_coefficient_of_variation': distribution_cv,
            'response_times': {
                'average': avg_response_time,
                'minimum': min_response_time,
                'maximum': max_response_time,
                'p95': p95_response_time
            },
            'status_code_distribution': dict(status_codes)
        }
    
    def test_session_stickiness(self, num_requests: int = 20) -> Dict:
        """Test if session stickiness is working (should not be sticky for this setup)"""
        print(f"🍪 Testing session stickiness with {num_requests} requests...")
        
        # Use the same session for all requests to test stickiness
        sticky_session = requests.Session()
        sticky_session.headers.update({'User-Agent': 'Stickiness-Tester/1.0'})
        
        instance_ids = []
        
        for i in range(num_requests):
            try:
                response = sticky_session.get(f"{self.base_url}/api/instance-info", timeout=10)
                if response.status_code == 200:
                    data = response.json()
                    instance_ids.append(data.get('instance_id', 'unknown'))
                else:
                    instance_ids.append('error')
                
                time.sleep(0.1)  # Small delay between requests
                
            except Exception:
                instance_ids.append('exception')
        
        unique_instances = len(set(instance_ids))
        most_common_instance = Counter(instance_ids).most_common(1)[0] if instance_ids else ('none', 0)
        stickiness_ratio = most_common_instance[1] / len(instance_ids) if instance_ids else 0
        
        return {
            'test': 'session_stickiness',
            'status': 'PASS' if unique_instances > 1 else 'INFO',  # We expect multiple instances (no stickiness)
            'total_requests': num_requests,
            'unique_instances': unique_instances,
            'instance_distribution': dict(Counter(instance_ids)),
            'stickiness_ratio': stickiness_ratio,
            'is_sticky': stickiness_ratio > 0.8,
            'note': 'Lower stickiness is expected for round-robin load balancing'
        }
    
    def test_concurrent_load(self, concurrent_users: int = 50, requests_per_user: int = 10) -> Dict:
        """Test ALB under concurrent load"""
        print(f"🚀 Testing concurrent load: {concurrent_users} users, {requests_per_user} requests each...")
        
        total_requests = concurrent_users * requests_per_user
        successful_requests = 0
        failed_requests = 0
        response_times = []
        status_codes = Counter()
        
        def user_session():
            session_results = []
            session = requests.Session()
            
            for _ in range(requests_per_user):
                try:
                    start_time = time.time()
                    response = session.get(f"{self.base_url}/api/status", timeout=15)
                    end_time = time.time()
                    
                    response_time = end_time - start_time
                    response_times.append(response_time)
                    status_codes[response.status_code] += 1
                    
                    if response.status_code == 200:
                        session_results.append('success')
                    else:
                        session_results.append('fail')
                        
                except Exception:
                    session_results.append('exception')
                    response_times.append(15)  # Timeout value
                    status_codes[0] += 1
            
            return session_results
        
        # Run concurrent user sessions
        with concurrent.futures.ThreadPoolExecutor(max_workers=concurrent_users) as executor:
            futures = [executor.submit(user_session) for _ in range(concurrent_users)]
            
            for future in concurrent.futures.as_completed(futures):
                results = future.result()
                successful_requests += results.count('success')
                failed_requests += results.count('fail') + results.count('exception')
        
        # Calculate performance metrics
        if response_times:
            avg_response_time = statistics.mean(response_times)
            p95_response_time = sorted(response_times)[int(len(response_times) * 0.95)]
            p99_response_time = sorted(response_times)[int(len(response_times) * 0.99)]
        else:
            avg_response_time = p95_response_time = p99_response_time = 0
        
        success_rate = (successful_requests / total_requests) * 100 if total_requests > 0 else 0
        
        return {
            'test': 'concurrent_load',
            'status': 'PASS' if success_rate > 95 else 'PARTIAL' if success_rate > 80 else 'FAIL',
            'concurrent_users': concurrent_users,
            'requests_per_user': requests_per_user,
            'total_requests': total_requests,
            'successful_requests': successful_requests,
            'failed_requests': failed_requests,
            'success_rate': success_rate,
            'performance_metrics': {
                'average_response_time': avg_response_time,
                'p95_response_time': p95_response_time,
                'p99_response_time': p99_response_time
            },
            'status_code_distribution': dict(status_codes)
        }
    
    def test_failover_simulation(self) -> Dict:
        """Test ALB behavior during simulated instance failure"""
        print("🔄 Testing failover behavior...")
        
        # First, identify available instances
        initial_instances = set()
        for _ in range(10):
            try:
                response = self.session.get(f"{self.base_url}/api/instance-info", timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    initial_instances.add(data.get('instance_id', 'unknown'))
            except:
                pass
        
        if len(initial_instances) < 2:
            return {
                'test': 'failover_simulation',
                'status': 'SKIP',
                'reason': 'Need at least 2 instances for failover testing',
                'initial_instances': list(initial_instances)
            }
        
        # Monitor instance availability over time
        monitoring_results = []
        monitoring_duration = 60  # seconds
        check_interval = 5  # seconds
        
        for i in range(0, monitoring_duration, check_interval):
            available_instances = set()
            check_results = []
            
            # Make multiple requests to see which instances respond
            for _ in range(10):
                try:
                    response = self.session.get(f"{self.base_url}/api/instance-info", timeout=3)
                    if response.status_code == 200:
                        data = response.json()
                        instance_id = data.get('instance_id', 'unknown')
                        available_instances.add(instance_id)
                        check_results.append({
                            'instance_id': instance_id,
                            'status': 'healthy',
                            'response_time': response.elapsed.total_seconds()
                        })
                    else:
                        check_results.append({
                            'status': 'unhealthy',
                            'status_code': response.status_code
                        })
                except Exception as e:
                    check_results.append({
                        'status': 'error',
                        'error': str(e)
                    })
            
            monitoring_results.append({
                'timestamp': i,
                'available_instances': list(available_instances),
                'instance_count': len(available_instances),
                'check_results': check_results
            })
            
            if i < monitoring_duration - check_interval:
                time.sleep(check_interval)
        
        # Analyze failover behavior
        instance_counts = [r['instance_count'] for r in monitoring_results]
        min_instances = min(instance_counts)
        max_instances = max(instance_counts)
        avg_instances = statistics.mean(instance_counts)
        
        return {
            'test': 'failover_simulation',
            'status': 'PASS' if min_instances > 0 else 'FAIL',
            'initial_instances': list(initial_instances),
            'monitoring_duration': monitoring_duration,
            'instance_availability': {
                'minimum': min_instances,
                'maximum': max_instances,
                'average': avg_instances
            },
            'monitoring_results': monitoring_results,
            'note': 'This test monitors natural instance availability changes'
        }
    
    def run_all_tests(self) -> Dict:
        """Run all load balancer tests"""
        print("🎯 Starting comprehensive Load Balancer testing...\n")
        
        tests = [
            self.test_basic_connectivity,
            self.test_health_checks,
            self.test_load_distribution,
            self.test_session_stickiness,
            self.test_concurrent_load,
            self.test_failover_simulation
        ]
        
        results = []
        
        for test in tests:
            try:
                print(f"Running {test.__name__}...")
                result = test()
                results.append(result)
                
                # Print test result
                status_emoji = "✅" if result['status'] == 'PASS' else "⚠️" if result['status'] in ['PARTIAL', 'INFO'] else "⏭️" if result['status'] == 'SKIP' else "❌"
                print(f"{status_emoji} {result['test']}: {result['status']}")
                
                # Print key metrics
                if 'unique_instances' in result:
                    print(f"   Unique instances: {result['unique_instances']}")
                if 'success_rate' in result:
                    print(f"   Success rate: {result['success_rate']:.1f}%")
                if 'response_times' in result and isinstance(result['response_times'], dict):
                    print(f"   Avg response time: {result['response_times']['average']:.3f}s")
                
                print()
                
            except Exception as e:
                results.append({
                    'test': test.__name__,
                    'status': 'ERROR',
                    'error': str(e)
                })
                print(f"❌ {test.__name__}: ERROR - {str(e)}\n")
        
        # Summary
        passed = sum(1 for r in results if r['status'] == 'PASS')
        partial = sum(1 for r in results if r['status'] in ['PARTIAL', 'INFO'])
        failed = sum(1 for r in results if r['status'] == 'FAIL')
        skipped = sum(1 for r in results if r['status'] == 'SKIP')
        errors = sum(1 for r in results if r['status'] == 'ERROR')
        
        print("=" * 60)
        print("⚖️ LOAD BALANCER TEST SUMMARY")
        print("=" * 60)
        print(f"✅ Passed: {passed}")
        print(f"⚠️ Partial/Info: {partial}")
        print(f"❌ Failed: {failed}")
        print(f"⏭️ Skipped: {skipped}")
        print(f"🔥 Errors: {errors}")
        
        total_scored = passed + partial + failed + errors  # Exclude skipped from scoring
        if total_scored > 0:
            success_rate = ((passed + partial * 0.5) / total_scored) * 100
            print(f"📊 Overall Success Rate: {success_rate:.1f}%")
        
        return {
            'summary': {
                'total_tests': len(results),
                'passed': passed,
                'partial': partial,
                'failed': failed,
                'skipped': skipped,
                'errors': errors,
                'success_rate': ((passed + partial * 0.5) / total_scored) * 100 if total_scored > 0 else 0
            },
            'detailed_results': results
        }

def main():
    parser = argparse.ArgumentParser(description='Test Application Load Balancer functionality')
    parser.add_argument('alb_dns_name', help='ALB DNS name')
    parser.add_argument('--output-file', help='Save results to JSON file')
    
    args = parser.parse_args()
    
    print(f"🎯 Testing Load Balancer at: {args.alb_dns_name}\n")
    
    tester = LoadBalancerTester(args.alb_dns_name)
    results = tester.run_all_tests()
    
    if args.output_file:
        with open(args.output_file, 'w') as f:
            json.dump(results, f, indent=2)
        print(f"\n💾 Results saved to: {args.output_file}")
    
    # Exit with appropriate code
    if results['summary']['success_rate'] >= 80:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
