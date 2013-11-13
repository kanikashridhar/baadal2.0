# -*- coding: utf-8 -*-
###################################################################################
# Added to enable code completion in IDE's.
if 0:
    from gluon import *  # @UnusedWildImport
    from gluon import db
    import gluon
    global auth; auth = gluon.tools.Auth()
    from applications.baadal.models import *  # @UnusedWildImport
###################################################################################
from helper import is_moderator

def verify_vm_request(request_id):
    db(db.request_queue.id == request_id).update(status=REQ_STATUS_VERIFIED)

def reject_vm_request(request_id):
    #Send Mail
    db(db.request_queue.id == request_id).delete()

def get_pending_requests():

    if is_moderator():
        _query = db(db.request_queue.status == REQ_STATUS_REQUESTED)
    else:
        _query = db((db.request_queue.status == REQ_STATUS_REQUESTED) & (db.request_queue.owner_id == auth.user.id))
    
    vm_requests = _query.select(db.request_queue.ALL)
    return get_pending_request_list(vm_requests)

