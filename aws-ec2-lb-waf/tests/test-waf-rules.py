#!/usr/bin/env python3
"""
Dedicated WAF rules testing script
Tests specific WAF rules and their effectiveness
"""

import requests
import json
import time
import sys
import argparse
from typing import Dict, List
import concurrent.futures

class WAFTester:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        
    def test_sql_injection_patterns(self) -> Dict:
        """Test various SQL injection patterns"""
        print("🔍 Testing SQL Injection patterns...")
        
        sql_patterns = [
            # Basic SQL injection
            "' OR 1=1 --",
            "' OR '1'='1",
            "admin'--",
            "' OR 1=1#",
            
            # Union-based injection
            "' UNION SELECT * FROM users --",
            "1' UNION SELECT username, password FROM users --",
            
            # Boolean-based blind injection
            "' AND 1=1 --",
            "' AND 1=2 --",
            
            # Time-based blind injection
            "'; WAITFOR DELAY '00:00:05' --",
            "' OR SLEEP(5) --",
            
            # Error-based injection
            "' AND (SELECT COUNT(*) FROM information_schema.tables) > 0 --",
            
            # Advanced patterns
            "'; DROP TABLE users; --",
            "' OR EXISTS(SELECT * FROM users WHERE username='admin') --",
            "1' AND EXTRACTVALUE(1, CONCAT(0x7e, (SELECT version()), 0x7e)) --"
        ]
        
        results = []
        blocked_count = 0
        
        for pattern in sql_patterns:
            try:
                response = self.session.get(
                    f"{self.base_url}/search",
                    params={'q': pattern},
                    timeout=10
                )
                
                blocked = response.status_code == 403
                if blocked:
                    blocked_count += 1
                
                results.append({
                    'pattern': pattern,
                    'status_code': response.status_code,
                    'blocked': blocked,
                    'response_time': response.elapsed.total_seconds()
                })
                
            except Exception as e:
                results.append({
                    'pattern': pattern,
                    'error': str(e),
                    'blocked': False
                })
        
        return {
            'test_name': 'SQL Injection Protection',
            'total_patterns': len(sql_patterns),
            'blocked_patterns': blocked_count,
            'block_rate': (blocked_count / len(sql_patterns)) * 100,
            'status': 'EXCELLENT' if blocked_count > len(sql_patterns) * 0.8 else 'GOOD' if blocked_count > len(sql_patterns) * 0.5 else 'POOR',
            'results': results
        }
    
    def test_xss_patterns(self) -> Dict:
        """Test various XSS patterns"""
        print("🔍 Testing XSS patterns...")
        
        xss_patterns = [
            # Basic XSS
            "<script>alert('XSS')</script>",
            "<img src=x onerror=alert('XSS')>",
            "<svg onload=alert('XSS')>",
            
            # Event handler XSS
            "<body onload=alert('XSS')>",
            "<input onfocus=alert('XSS') autofocus>",
            "<select onfocus=alert('XSS') autofocus>",
            
            # JavaScript protocol
            "javascript:alert('XSS')",
            "JaVaScRiPt:alert('XSS')",
            
            # Encoded XSS
            "%3Cscript%3Ealert('XSS')%3C/script%3E",
            "&#60;script&#62;alert('XSS')&#60;/script&#62;",
            
            # Advanced XSS
            "<iframe src=javascript:alert('XSS')>",
            "<object data=javascript:alert('XSS')>",
            "<embed src=javascript:alert('XSS')>",
            
            # Filter evasion
            "<scr<script>ipt>alert('XSS')</scr</script>ipt>",
            "<<SCRIPT>alert('XSS')//<</SCRIPT>",
            
            # CSS-based XSS
            "<style>@import'javascript:alert(\"XSS\")';</style>",
            "<link rel=stylesheet href=javascript:alert('XSS')>"
        ]
        
        results = []
        blocked_count = 0
        
        for pattern in xss_patterns:
            try:
                # Test via POST request (comment endpoint)
                response = self.session.post(
                    f"{self.base_url}/comment",
                    json={'comment': pattern},
                    headers={'Content-Type': 'application/json'},
                    timeout=10
                )
                
                blocked = response.status_code == 403
                if blocked:
                    blocked_count += 1
                
                results.append({
                    'pattern': pattern,
                    'status_code': response.status_code,
                    'blocked': blocked,
                    'response_time': response.elapsed.total_seconds()
                })
                
            except Exception as e:
                results.append({
                    'pattern': pattern,
                    'error': str(e),
                    'blocked': False
                })
        
        return {
            'test_name': 'XSS Protection',
            'total_patterns': len(xss_patterns),
            'blocked_patterns': blocked_count,
            'block_rate': (blocked_count / len(xss_patterns)) * 100,
            'status': 'EXCELLENT' if blocked_count > len(xss_patterns) * 0.8 else 'GOOD' if blocked_count > len(xss_patterns) * 0.5 else 'POOR',
            'results': results
        }
    
    def test_rate_limiting(self, requests_per_minute: int = 100) -> Dict:
        """Test rate limiting functionality"""
        print(f"🔍 Testing rate limiting with {requests_per_minute} requests...")
        
        blocked_requests = 0
        successful_requests = 0
        error_requests = 0
        
        def make_request():
            try:
                response = self.session.get(f"{self.base_url}/api/data", timeout=5)
                if response.status_code == 403:
                    return 'blocked'
                elif response.status_code == 200:
                    return 'success'
                else:
                    return 'other'
            except:
                return 'error'
        
        # Make concurrent requests to test rate limiting
        with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
            futures = [executor.submit(make_request) for _ in range(requests_per_minute)]
            
            for future in concurrent.futures.as_completed(futures):
                result = future.result()
                if result == 'blocked':
                    blocked_requests += 1
                elif result == 'success':
                    successful_requests += 1
                elif result == 'error':
                    error_requests += 1
        
        total_requests = blocked_requests + successful_requests + error_requests
        
        return {
            'test_name': 'Rate Limiting',
            'total_requests': total_requests,
            'successful_requests': successful_requests,
            'blocked_requests': blocked_requests,
            'error_requests': error_requests,
            'block_rate': (blocked_requests / total_requests) * 100 if total_requests > 0 else 0,
            'status': 'EXCELLENT' if blocked_requests > 0 else 'POOR'
        }
    
    def test_malicious_user_agents(self) -> Dict:
        """Test blocking of malicious user agents"""
        print("🔍 Testing malicious user agent blocking...")
        
        malicious_agents = [
            "badbot",
            "BadBot/1.0",
            "malicious-scanner",
            "BADBOT-Scanner",
            "evil-crawler",
            "BadBot-Crawler/2.0",
            "malware-bot",
            "BadBotNet/1.0"
        ]
        
        results = []
        blocked_count = 0
        
        for agent in malicious_agents:
            try:
                headers = {'User-Agent': agent}
                response = requests.get(
                    f"{self.base_url}/api/status",
                    headers=headers,
                    timeout=10
                )
                
                blocked = response.status_code == 403
                if blocked:
                    blocked_count += 1
                
                results.append({
                    'user_agent': agent,
                    'status_code': response.status_code,
                    'blocked': blocked
                })
                
            except Exception as e:
                results.append({
                    'user_agent': agent,
                    'error': str(e),
                    'blocked': False
                })
        
        return {
            'test_name': 'Malicious User Agent Blocking',
            'total_agents': len(malicious_agents),
            'blocked_agents': blocked_count,
            'block_rate': (blocked_count / len(malicious_agents)) * 100,
            'status': 'EXCELLENT' if blocked_count > len(malicious_agents) * 0.8 else 'GOOD' if blocked_count > 0 else 'POOR',
            'results': results
        }
    
    def test_path_traversal(self) -> Dict:
        """Test path traversal attack protection"""
        print("🔍 Testing path traversal protection...")
        
        traversal_patterns = [
            "../../../etc/passwd",
            "..\\..\\..\\windows\\system32\\drivers\\etc\\hosts",
            "....//....//....//etc/passwd",
            "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd",
            "..%252f..%252f..%252fetc%252fpasswd",
            "..%c0%af..%c0%af..%c0%afetc%c0%afpasswd",
            "../../../../../../etc/passwd%00.jpg",
            "../../../etc/passwd\x00.png"
        ]
        
        results = []
        blocked_count = 0
        
        for pattern in traversal_patterns:
            try:
                response = self.session.get(
                    f"{self.base_url}/api/file",
                    params={'path': pattern},
                    timeout=10
                )
                
                blocked = response.status_code == 403
                if blocked:
                    blocked_count += 1
                
                results.append({
                    'pattern': pattern,
                    'status_code': response.status_code,
                    'blocked': blocked
                })
                
            except Exception as e:
                results.append({
                    'pattern': pattern,
                    'error': str(e),
                    'blocked': False
                })
        
        return {
            'test_name': 'Path Traversal Protection',
            'total_patterns': len(traversal_patterns),
            'blocked_patterns': blocked_count,
            'block_rate': (blocked_count / len(traversal_patterns)) * 100,
            'status': 'EXCELLENT' if blocked_count > len(traversal_patterns) * 0.8 else 'GOOD' if blocked_count > 0 else 'POOR',
            'results': results
        }
    
    def test_admin_path_blocking(self) -> Dict:
        """Test blocking of admin paths"""
        print("🔍 Testing admin path blocking...")
        
        admin_paths = [
            "/admin",
            "/admin/",
            "/admin/login",
            "/admin/dashboard",
            "/administrator",
            "/wp-admin",
            "/phpmyadmin",
            "/admin.php",
            "/admin/index.php",
            "/backend"
        ]
        
        results = []
        blocked_count = 0
        
        for path in admin_paths:
            try:
                response = self.session.get(f"{self.base_url}{path}", timeout=10)
                
                blocked = response.status_code == 403
                if blocked:
                    blocked_count += 1
                
                results.append({
                    'path': path,
                    'status_code': response.status_code,
                    'blocked': blocked
                })
                
            except Exception as e:
                results.append({
                    'path': path,
                    'error': str(e),
                    'blocked': False
                })
        
        return {
            'test_name': 'Admin Path Blocking',
            'total_paths': len(admin_paths),
            'blocked_paths': blocked_count,
            'block_rate': (blocked_count / len(admin_paths)) * 100,
            'status': 'EXCELLENT' if blocked_count > len(admin_paths) * 0.8 else 'GOOD' if blocked_count > 0 else 'POOR',
            'results': results
        }
    
    def run_comprehensive_waf_tests(self) -> Dict:
        """Run all WAF tests"""
        print("🛡️ Starting comprehensive WAF testing...\n")
        
        tests = [
            self.test_sql_injection_patterns,
            self.test_xss_patterns,
            self.test_rate_limiting,
            self.test_malicious_user_agents,
            self.test_path_traversal,
            self.test_admin_path_blocking
        ]
        
        results = []
        
        for test in tests:
            try:
                result = test()
                results.append(result)
                
                # Print test result
                status_emoji = "🟢" if result['status'] == 'EXCELLENT' else "🟡" if result['status'] == 'GOOD' else "🔴"
                print(f"{status_emoji} {result['test_name']}: {result['status']}")
                
                if 'block_rate' in result:
                    print(f"   Block Rate: {result['block_rate']:.1f}%")
                
                print()
                
            except Exception as e:
                results.append({
                    'test_name': test.__name__,
                    'status': 'ERROR',
                    'error': str(e)
                })
                print(f"🔴 {test.__name__}: ERROR - {str(e)}\n")
        
        # Calculate overall WAF effectiveness
        excellent_count = sum(1 for r in results if r.get('status') == 'EXCELLENT')
        good_count = sum(1 for r in results if r.get('status') == 'GOOD')
        poor_count = sum(1 for r in results if r.get('status') == 'POOR')
        
        overall_score = (excellent_count * 3 + good_count * 2 + poor_count * 1) / (len(results) * 3) * 100
        
        print("=" * 60)
        print("🛡️ WAF PROTECTION SUMMARY")
        print("=" * 60)
        print(f"🟢 Excellent Protection: {excellent_count}")
        print(f"🟡 Good Protection: {good_count}")
        print(f"🔴 Poor Protection: {poor_count}")
        print(f"📊 Overall WAF Score: {overall_score:.1f}%")
        
        if overall_score >= 80:
            print("✅ WAF is providing excellent protection!")
        elif overall_score >= 60:
            print("⚠️ WAF is providing good protection, but could be improved.")
        else:
            print("❌ WAF protection needs significant improvement.")
        
        return {
            'summary': {
                'total_tests': len(results),
                'excellent': excellent_count,
                'good': good_count,
                'poor': poor_count,
                'overall_score': overall_score
            },
            'detailed_results': results
        }

def main():
    parser = argparse.ArgumentParser(description='Test WAF rules effectiveness')
    parser.add_argument('base_url', help='Base URL of the application (e.g., http://alb-dns-name)')
    parser.add_argument('--output-file', help='Save results to JSON file')
    
    args = parser.parse_args()
    
    print(f"🎯 Testing WAF at: {args.base_url}\n")
    
    tester = WAFTester(args.base_url)
    results = tester.run_comprehensive_waf_tests()
    
    if args.output_file:
        with open(args.output_file, 'w') as f:
            json.dump(results, f, indent=2)
        print(f"\n💾 Results saved to: {args.output_file}")
    
    # Exit with appropriate code based on overall score
    if results['summary']['overall_score'] >= 60:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
