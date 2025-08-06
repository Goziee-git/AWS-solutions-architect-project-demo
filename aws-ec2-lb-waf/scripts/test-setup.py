#!/usr/bin/env python3
"""
Comprehensive testing script for AWS EC2 + ALB + WAF Demo
This script tests all components of the infrastructure to ensure proper functionality.
"""

import requests
import json
import time
import sys
import subprocess
import concurrent.futures
from typing import Dict, List, Tuple
import argparse

class InfrastructureTester:
    def __init__(self, alb_dns_name: str):
        self.base_url = f"http://{alb_dns_name}"
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Infrastructure-Tester/1.0'
        })
        
    def test_basic_connectivity(self) -> Dict:
        """Test basic connectivity to the load balancer"""
        print("🔗 Testing basic connectivity...")
        
        try:
            response = self.session.get(self.base_url, timeout=10)
            return {
                'test': 'basic_connectivity',
                'status': 'PASS' if response.status_code == 200 else 'FAIL',
                'status_code': response.status_code,
                'response_time': response.elapsed.total_seconds(),
                'content_length': len(response.content)
            }
        except Exception as e:
            return {
                'test': 'basic_connectivity',
                'status': 'FAIL',
                'error': str(e)
            }
    
    def test_health_endpoint(self) -> Dict:
        """Test the health check endpoint"""
        print("🏥 Testing health endpoint...")
        
        try:
            response = self.session.get(f"{self.base_url}/health", timeout=10)
            data = response.json() if response.headers.get('content-type', '').startswith('application/json') else {}
            
            return {
                'test': 'health_endpoint',
                'status': 'PASS' if response.status_code == 200 and data.get('status') == 'healthy' else 'FAIL',
                'status_code': response.status_code,
                'response_data': data,
                'response_time': response.elapsed.total_seconds()
            }
        except Exception as e:
            return {
                'test': 'health_endpoint',
                'status': 'FAIL',
                'error': str(e)
            }
    
    def test_load_balancing(self, num_requests: int = 20) -> Dict:
        """Test load balancing across multiple instances"""
        print(f"⚖️ Testing load balancing with {num_requests} requests...")
        
        instance_counts = {}
        successful_requests = 0
        failed_requests = 0
        
        def make_request():
            try:
                response = self.session.get(f"{self.base_url}/api/instance-info", timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    return data.get('instance_id', 'unknown')
                return None
            except:
                return None
        
        # Use ThreadPoolExecutor for concurrent requests
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(make_request) for _ in range(num_requests)]
            
            for future in concurrent.futures.as_completed(futures):
                result = future.result()
                if result:
                    instance_counts[result] = instance_counts.get(result, 0) + 1
                    successful_requests += 1
                else:
                    failed_requests += 1
        
        return {
            'test': 'load_balancing',
            'status': 'PASS' if len(instance_counts) > 1 and successful_requests > 0 else 'PARTIAL' if successful_requests > 0 else 'FAIL',
            'total_requests': num_requests,
            'successful_requests': successful_requests,
            'failed_requests': failed_requests,
            'instance_distribution': instance_counts,
            'unique_instances': len(instance_counts)
        }
    
    def test_waf_sql_injection(self) -> Dict:
        """Test WAF protection against SQL injection"""
        print("🛡️ Testing WAF SQL injection protection...")
        
        malicious_payloads = [
            "' OR 1=1 --",
            "'; DROP TABLE users; --",
            "1' UNION SELECT * FROM users --",
            "admin'--",
            "' OR 'a'='a"
        ]
        
        results = []
        for payload in malicious_payloads:
            try:
                response = self.session.get(f"{self.base_url}/search", params={'q': payload}, timeout=10)
                results.append({
                    'payload': payload,
                    'status_code': response.status_code,
                    'blocked': response.status_code == 403
                })
            except Exception as e:
                results.append({
                    'payload': payload,
                    'error': str(e),
                    'blocked': False
                })
        
        blocked_count = sum(1 for r in results if r.get('blocked', False))
        
        return {
            'test': 'waf_sql_injection',
            'status': 'PASS' if blocked_count > 0 else 'FAIL',
            'total_payloads': len(malicious_payloads),
            'blocked_payloads': blocked_count,
            'results': results
        }
    
    def test_waf_xss_protection(self) -> Dict:
        """Test WAF protection against XSS attacks"""
        print("🛡️ Testing WAF XSS protection...")
        
        xss_payloads = [
            "<script>alert('XSS')</script>",
            "<img src=x onerror=alert('XSS')>",
            "javascript:alert('XSS')",
            "<svg onload=alert('XSS')>",
            "';alert('XSS');//"
        ]
        
        results = []
        for payload in xss_payloads:
            try:
                response = self.session.post(
                    f"{self.base_url}/comment",
                    json={'comment': payload},
                    headers={'Content-Type': 'application/json'},
                    timeout=10
                )
                results.append({
                    'payload': payload,
                    'status_code': response.status_code,
                    'blocked': response.status_code == 403
                })
            except Exception as e:
                results.append({
                    'payload': payload,
                    'error': str(e),
                    'blocked': False
                })
        
        blocked_count = sum(1 for r in results if r.get('blocked', False))
        
        return {
            'test': 'waf_xss_protection',
            'status': 'PASS' if blocked_count > 0 else 'FAIL',
            'total_payloads': len(xss_payloads),
            'blocked_payloads': blocked_count,
            'results': results
        }
    
    def test_waf_rate_limiting(self, num_requests: int = 50) -> Dict:
        """Test WAF rate limiting"""
        print(f"🛡️ Testing WAF rate limiting with {num_requests} rapid requests...")
        
        blocked_requests = 0
        successful_requests = 0
        
        # Make rapid requests to trigger rate limiting
        for i in range(num_requests):
            try:
                response = self.session.get(f"{self.base_url}/api/data", timeout=5)
                if response.status_code == 403:
                    blocked_requests += 1
                elif response.status_code == 200:
                    successful_requests += 1
                
                # Small delay to avoid overwhelming the system
                time.sleep(0.1)
                
            except Exception:
                pass
        
        return {
            'test': 'waf_rate_limiting',
            'status': 'PASS' if blocked_requests > 0 else 'PARTIAL',
            'total_requests': num_requests,
            'successful_requests': successful_requests,
            'blocked_requests': blocked_requests,
            'block_rate': blocked_requests / num_requests if num_requests > 0 else 0
        }
    
    def test_waf_bad_user_agent(self) -> Dict:
        """Test WAF protection against bad user agents"""
        print("🛡️ Testing WAF bad user agent protection...")
        
        bad_user_agents = [
            "badbot",
            "BadBot/1.0",
            "malicious-scanner",
            "BADBOT-Scanner"
        ]
        
        results = []
        for user_agent in bad_user_agents:
            try:
                headers = {'User-Agent': user_agent}
                response = requests.get(f"{self.base_url}/api/status", headers=headers, timeout=10)
                results.append({
                    'user_agent': user_agent,
                    'status_code': response.status_code,
                    'blocked': response.status_code == 403
                })
            except Exception as e:
                results.append({
                    'user_agent': user_agent,
                    'error': str(e),
                    'blocked': False
                })
        
        blocked_count = sum(1 for r in results if r.get('blocked', False))
        
        return {
            'test': 'waf_bad_user_agent',
            'status': 'PASS' if blocked_count > 0 else 'FAIL',
            'total_user_agents': len(bad_user_agents),
            'blocked_user_agents': blocked_count,
            'results': results
        }
    
    def test_api_endpoints(self) -> Dict:
        """Test various API endpoints"""
        print("🔌 Testing API endpoints...")
        
        endpoints = [
            '/api/status',
            '/api/instance-info',
            '/api/data'
        ]
        
        results = []
        for endpoint in endpoints:
            try:
                response = self.session.get(f"{self.base_url}{endpoint}", timeout=10)
                results.append({
                    'endpoint': endpoint,
                    'status_code': response.status_code,
                    'response_time': response.elapsed.total_seconds(),
                    'success': response.status_code == 200
                })
            except Exception as e:
                results.append({
                    'endpoint': endpoint,
                    'error': str(e),
                    'success': False
                })
        
        successful_endpoints = sum(1 for r in results if r.get('success', False))
        
        return {
            'test': 'api_endpoints',
            'status': 'PASS' if successful_endpoints == len(endpoints) else 'PARTIAL' if successful_endpoints > 0 else 'FAIL',
            'total_endpoints': len(endpoints),
            'successful_endpoints': successful_endpoints,
            'results': results
        }
    
    def run_all_tests(self) -> Dict:
        """Run all tests and return comprehensive results"""
        print("🚀 Starting comprehensive infrastructure tests...\n")
        
        tests = [
            self.test_basic_connectivity,
            self.test_health_endpoint,
            self.test_api_endpoints,
            self.test_load_balancing,
            self.test_waf_sql_injection,
            self.test_waf_xss_protection,
            self.test_waf_rate_limiting,
            self.test_waf_bad_user_agent
        ]
        
        results = []
        for test in tests:
            try:
                result = test()
                results.append(result)
                
                # Print test result
                status_emoji = "✅" if result['status'] == 'PASS' else "⚠️" if result['status'] == 'PARTIAL' else "❌"
                print(f"{status_emoji} {result['test']}: {result['status']}")
                
            except Exception as e:
                results.append({
                    'test': test.__name__,
                    'status': 'ERROR',
                    'error': str(e)
                })
                print(f"❌ {test.__name__}: ERROR - {str(e)}")
            
            print()  # Add spacing between tests
        
        # Summary
        passed = sum(1 for r in results if r['status'] == 'PASS')
        partial = sum(1 for r in results if r['status'] == 'PARTIAL')
        failed = sum(1 for r in results if r['status'] in ['FAIL', 'ERROR'])
        
        print("=" * 50)
        print("📊 TEST SUMMARY")
        print("=" * 50)
        print(f"✅ Passed: {passed}")
        print(f"⚠️ Partial: {partial}")
        print(f"❌ Failed: {failed}")
        print(f"📈 Success Rate: {(passed / len(results)) * 100:.1f}%")
        
        return {
            'summary': {
                'total_tests': len(results),
                'passed': passed,
                'partial': partial,
                'failed': failed,
                'success_rate': (passed / len(results)) * 100
            },
            'detailed_results': results
        }

def get_terraform_output(output_name: str) -> str:
    """Get Terraform output value"""
    try:
        result = subprocess.run(
            ['terraform', 'output', '-raw', output_name],
            cwd='../infrastructure',
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None

def main():
    parser = argparse.ArgumentParser(description='Test AWS EC2 + ALB + WAF infrastructure')
    parser.add_argument('--alb-dns', help='ALB DNS name (if not provided, will try to get from Terraform output)')
    parser.add_argument('--output-file', help='Save results to JSON file')
    
    args = parser.parse_args()
    
    # Get ALB DNS name
    alb_dns_name = args.alb_dns
    if not alb_dns_name:
        print("🔍 Getting ALB DNS name from Terraform output...")
        alb_dns_name = get_terraform_output('load_balancer_dns_name')
        
        if not alb_dns_name:
            print("❌ Could not get ALB DNS name. Please provide it with --alb-dns argument")
            sys.exit(1)
    
    print(f"🎯 Testing infrastructure at: {alb_dns_name}\n")
    
    # Run tests
    tester = InfrastructureTester(alb_dns_name)
    results = tester.run_all_tests()
    
    # Save results if requested
    if args.output_file:
        with open(args.output_file, 'w') as f:
            json.dump(results, f, indent=2)
        print(f"\n💾 Results saved to: {args.output_file}")
    
    # Exit with appropriate code
    if results['summary']['failed'] > 0:
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()
