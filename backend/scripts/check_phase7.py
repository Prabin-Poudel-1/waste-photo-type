"""Targeted Phase 7 HTTP/security checks. Uses disposable fixtures; no existing rows changed.
Run against a development backend with PHASE7_BASE_URL and standard PG* variables.
"""
import json, os, subprocess, uuid, urllib.request, urllib.error
base=os.environ.get('PHASE7_BASE_URL','http://127.0.0.1:18081/api/v1')
users=[]; departments=[]; reports=[]; tokens={}; spot=None
suffix=uuid.uuid4().hex

def sql(query):
    return subprocess.check_output([os.environ.get('PSQL','psql'),'-At','-v','ON_ERROR_STOP=1','-c',query],text=True).strip()
def insert(query): return int(sql(query).splitlines()[0])
def request(path,token=None,data=None):
    headers={'Content-Type':'application/json'}
    if token: headers['Authorization']='Bearer '+token
    try:
        with urllib.request.urlopen(urllib.request.Request(base+path,json.dumps(data).encode() if data else None,headers)) as r:
            return r.status,json.load(r)
    except urllib.error.HTTPError as e: return e.code,e.read().decode()
def get(path,role):
    code,data=request(path,tokens[role]); assert code==200,(code,data); return data
bounds='/maps/reports?south=0&west=0&north=1&east=1'
try:
    for role in ['USER','OTHER','ADMIN','DEPT_A','DEPT_B']:
        email=f'phase7-{role.lower()}-{suffix}@example.test'; password=uuid.uuid4().hex
        code,data=request('/auth/register',data={'name':'Phase7 temporary check','email':email,'password':password})
        assert code==201,(code,data)
        uid=data['user']['id']; users.append(uid)
        if role.startswith('DEPT'):
            did=insert(f"INSERT INTO departments(name) VALUES ('Phase7 {role} {suffix}') RETURNING id"); departments.append(did)
            sql(f"UPDATE app_users SET role='DEPARTMENT',department_id={did} WHERE id={uid}")
        elif role=='ADMIN': sql(f"UPDATE app_users SET role='ADMIN' WHERE id={uid}")
        code,data=request('/auth/login',data={'email':email,'password':password}); assert code==200
        tokens[role]=data['token']
    before=get('/authority/insights','ADMIN')['overview']
    spot=insert(f"INSERT INTO tourist_spots(name,latitude,longitude,radius_meters,active) VALUES ('Phase7 {suffix}',0.1,0.2,500,true) RETURNING id")
    category=int(sql('SELECT id FROM waste_categories ORDER BY id LIMIT 1'))
    for index,status in enumerate(['SUBMITTED','VERIFIED','ASSIGNED','IN_PROGRESS','RESOLVED','REJECTED']):
        rid=insert(f"INSERT INTO waste_reports(reporter_id,description,latitude,longitude,severity,current_status,tourist_spot_id) VALUES ({users[0]},'PRIVATE SENTINEL',0.1,0.2,'LOW','{status}',{spot}) RETURNING id"); reports.append(rid)
        sql(f"INSERT INTO waste_detections(report_id,waste_category_id,detected_label,confidence) VALUES ({rid},{category},'Private original label',0.9)")
        if index>=2:
            did=departments[0] if index in [2,4] else departments[1]
            sql(f'INSERT INTO report_assignments(report_id,department_id) VALUES ({rid},{did})')
    assert request(bounds)[0]==401
    assert request('/authority/insights',tokens['USER'])[0]==403
    public=get(bounds,'USER')['reports']; relevant=[r for r in public if r['id'] in reports]
    assert len(relevant)==5 and all(r['canViewDetails'] for r in relevant)
    expected={'id','latitude','longitude','statusGroup','touristSpot','createdAt','categories','canViewDetails'}
    assert all(set(r)==expected for r in public)
    assert 'PRIVATE SENTINEL' not in json.dumps(public) and 'example.test' not in json.dumps(public)
    assert all(not r['canViewDetails'] for r in get(bounds,'OTHER')['reports'] if r['id'] in reports)
    assert {r['statusGroup'] for r in relevant}=={'ATTENTION','HANDLING','RESOLVED'}
    assert len([r for r in get(bounds+'&filter=ACTIVE','USER')['reports'] if r['id'] in reports])==4
    assert [r['id'] for r in get(bounds+'&filter=RESOLVED','USER')['reports'] if r['id'] in reports]==[reports[4]]
    assert request('/maps/reports?south=2&north=1&west=0&east=1',tokens['USER'])[0]==400
    assert request(bounds+'&filter=INVALID',tokens['USER'])[0]==400
    assert {r['id'] for r in get(bounds,'DEPT_A')['reports']}=={reports[2],reports[4]}
    assert {r['id'] for r in get(bounds,'DEPT_B')['reports']}=={reports[3]}
    da=get('/authority/insights','DEPT_A'); assert da['overview']['total']==2 and da['overview']['resolved']==1 and da['touristSpots']==[] and da['categories']==[]
    assert request(f'/reports/{reports[2]}',tokens['DEPT_B'])[0]==404
    after=get('/authority/insights','ADMIN')
    for key,delta in [('total',6),('active',4),('submitted',1),('assigned',1),('inProgress',1),('resolved',1)]: assert after['overview'][key]==before[key]+delta,(key,after)
    expected_spots=json.loads(sql("SELECT coalesce(json_agg(x),'[]') FROM (SELECT t.name,count(*) AS count FROM waste_reports r JOIN tourist_spots t ON t.id=r.tourist_spot_id WHERE current_status<>'REJECTED' GROUP BY t.id,t.name ORDER BY count DESC,t.name LIMIT 10) x"))
    assert after['touristSpots']==expected_spots
    expected_categories=json.loads(sql("SELECT coalesce(json_agg(x),'[]') FROM (SELECT c.name,count(*) AS count FROM waste_detections d JOIN waste_categories c ON c.id=d.waste_category_id JOIN waste_reports r ON r.id=d.report_id WHERE current_status<>'REJECTED' GROUP BY c.id,c.name ORDER BY count DESC,c.name LIMIT 10) x"))
    assert after['categories']==expected_categories
    print('PASS: authentication, safe DTO, owner detail capability, rejected exclusion, filters, bounds validation, two-department isolation, department counts, admin aggregate counts/rankings.')
finally:
    if reports:
        ids=','.join(map(str,reports)); sql(f'DELETE FROM report_assignments WHERE report_id IN ({ids}); DELETE FROM waste_detections WHERE report_id IN ({ids}); DELETE FROM waste_reports WHERE id IN ({ids});')
    if spot: sql(f'DELETE FROM tourist_spots WHERE id={spot}')
    if users: sql('DELETE FROM app_users WHERE id IN ('+','.join(map(str,users))+')')
    if departments: sql('DELETE FROM departments WHERE id IN ('+','.join(map(str,departments))+')')
    print('Removed only this run’s temporary fixtures; existing data preserved.')
