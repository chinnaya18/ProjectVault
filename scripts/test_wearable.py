import urllib.request
import json

def test_wearable():
    q = "Wearable Health Monitoring Device"
    print("=" * 60)
    print(f"TESTING QUERY: '{q}'")
    print("=" * 60)
    
    req = urllib.request.Request(
        'http://localhost:8000/api/v1/ai/search',
        data=json.dumps({'query': q, 'limit': 6, 'threshold': 0.20}).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        print(f"Total Found: {data['total_results']}\n")
        for r in data['results']:
            print(f"[{r['similarity_score']:.4f}] #{r['id']} - {r['title']} (Domain: {r.get('domain')})")

if __name__ == '__main__':
    test_wearable()
