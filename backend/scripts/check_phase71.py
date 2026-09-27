"""Targeted management checks; development database only. Uses standard PG* env and PHASE7_BASE_URL."""
import json, os, subprocess, uuid, urllib.request, urllib.error
base=os.environ.get('PHASE7_BASE_URL','http://127.0.0.1:18081/api/v1')
users=[]; departments=[]; reports=[]; tokens={}; spot=None
suffix=uuid.uuid4().hex

def sql(query):
    return subprocess.check_output([os.environ.get('PSQL','psql'),'-At','-v','ON_ERROR_STOP=1','-c',query],text=True).strip()
def insert(query): return int(sql(query).splitlines()[0])
def request(path,token=None,data=None,method=None):
    headers={'Content-Type':'application/json'}
    if token: headers['Authorization']='Bearer '+token
    try:
        with urllib.request.urlopen(urllib.request.Request(base+path,json.dumps(data).encode() if data else None,headers,method=method)) as r:
            return r.status,json.load(r)
    except urllib.error.HTTPError as e: return e.code,e.read().decode()
def get(path,role):
    code,data=request(path,tokens[role]); assert code==200,(code,data); return data
try:
    for role in ['USER','DEPARTMENT','ADMIN']:
        email=f'phase71-{role.lower()}-{suffix}@example.test'; password=uuid.uuid4().hex
        code,data=request('/auth/register',data={'name':'Phase71 temporary check','email':email,'password':password}); assert code==201,(code,data)
        uid=data['user']['id']; users.append(uid)
        if role!='USER': sql(f"UPDATE app_users SET role='{role}' WHERE id={uid}")
        code,data=request('/auth/login',data={'email':email,'password':password}); assert code==200
        tokens[role]=data['token']
    prefix='/admin/management/'
    dept={'name':f'Phase71 department {suffix}','description':'Test description','active':True}
    tourist={'name':f'Phase71 spot {suffix}','description':'Test spot','latitude':27.69957,'longitude':84.42201,'radiusMeters':700,'address':'Test address','active':True}
    for kind,body in [('departments',dept),('tourist-spots',tourist)]:
        assert request(prefix+kind)[0]==401
        for role in ['USER','DEPARTMENT']:
            assert request(prefix+kind,tokens[role])[0]==403
            assert request(prefix+kind,tokens[role],body,'POST')[0]==403
            assert request(prefix+kind+'/1',tokens[role],{**body,'active':False},'PUT')[0]==403
        assert request(prefix+kind,tokens['ADMIN'],{**body,'name':'   '},'POST')[0]==400
        code,record=request(prefix+kind,tokens['ADMIN'],body,'POST'); assert code==201,(code,record)
        if kind=='departments': departments.append(record['id']); did=record['id']
        else: spot=record['id']
        assert any(r['id']==record['id'] for r in get(prefix+kind,'ADMIN'))
        assert request(prefix+kind,tokens['ADMIN'],{**body,'name':'  '+body['name'].upper()+'  '},'POST')[0]==409
        assert request(prefix+kind+'/'+str(record['id']),tokens['USER'],{**body,'active':False},'PUT')[0]==403
        assert request(prefix+kind+'/'+str(record['id']),tokens['DEPARTMENT'],{**body,'active':False},'PUT')[0]==403
    assert request(prefix+'tourist-spots',tokens['ADMIN'],{**tourist,'latitude':91},'POST')[0]==400
    assert request(prefix+'tourist-spots',tokens['ADMIN'],{**tourist,'radiusMeters':0},'POST')[0]==400
    sql(f"UPDATE app_users SET department_id={did} WHERE id={users[1]}")
    sql(f"UPDATE departments SET contact_email='preserve@example.test' WHERE id={did}")
    rid=insert(f"INSERT INTO waste_reports(reporter_id,latitude,longitude,severity,current_status,tourist_spot_id) VALUES ({users[0]},27.69957,84.42201,'LOW','ASSIGNED',{spot}) RETURNING id"); reports.append(rid)
    sql(f'INSERT INTO report_assignments(report_id,department_id) VALUES ({rid},{did})')
    for kind,body,id in [('departments',dept,did),('tourist-spots',tourist,spot)]:
        assert any(r['id']==id for r in request('/'+kind)[1])
        changed={**body,'name':body['name']+' edited','description':'Edited','active':False}
        code,record=request(prefix+kind+'/'+str(id),tokens['ADMIN'],changed,'PUT'); assert code==200,(code,record)
        assert record['id']==id and not record['active'] and record['description']=='Edited'
        assert all(r['id']!=id for r in request('/'+kind)[1])
        assert any(r['id']==id and not r['active'] for r in get(prefix+kind,'ADMIN'))
        assert request(prefix+kind+'/'+str(id),tokens['ADMIN'],method='DELETE')[0] in [403,405]
    assert sql(f'SELECT department_id FROM app_users WHERE id={users[1]}')==str(did)
    assert sql(f'SELECT department_id FROM report_assignments WHERE report_id={rid}')==str(did)
    assert sql(f'SELECT tourist_spot_id FROM waste_reports WHERE id={rid}')==str(spot)
    assert sql(f'SELECT contact_email FROM departments WHERE id={did}')=='preserve@example.test'
    for role in ['ADMIN','USER']:
        record=get(f'/reports/{rid}',role); assert record['touristSpot']['id']==spot
    for kind,body,id in [('departments',dept,did),('tourist-spots',tourist,spot)]:
        code,record=request(prefix+kind+'/'+str(id),tokens['ADMIN'],body,'PUT'); assert code==200 and record['active']
        assert any(r['id']==id for r in request('/'+kind)[1])
    print('PASS: Admin list/create/edit/deactivate/reactivate; USER/DEPARTMENT denied GET/POST/PUT; validation; duplicate prevention; active catalogs; existing IDs, contacts, user links, assignments and historical spot references preserved.')
finally:
    if reports:
        ids=','.join(map(str,reports));sql(f'DELETE FROM report_assignments WHERE report_id IN ({ids}); DELETE FROM waste_reports WHERE id IN ({ids});')
    if spot: sql(f'DELETE FROM tourist_spots WHERE id={spot}')
    if users: sql('DELETE FROM app_users WHERE id IN ('+','.join(map(str,users))+')')
    if departments: sql('DELETE FROM departments WHERE id IN ('+','.join(map(str,departments))+')')
    print('Only temporary test fixtures removed.')
