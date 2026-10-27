import copy
import unittest
from cleanup_consolidated_branches import deletion_plan, push_arguments, REPOSITORY

class CleanupTests(unittest.TestCase):
    def setUp(self):
        self.anchor='a'*40;self.run='b'*40;self.branch='c'*40
        self.manifest={'repository':REPOSITORY,'integration_commit':self.anchor,'branches':[
            {'name':'main','sha':self.anchor,'action':'keep'},
            {'name':'feature/additive','sha':self.branch,'action':'delete-after-integration'}]}
        self.heads={'main':self.run,'feature/additive':self.branch}
    def plan(self, ancestor=lambda a,b:True):
        return deletion_plan(self.manifest,self.heads,self.run,self.anchor,ancestor)
    def test_only_preserved_names_deleted(self):
        plan=self.plan();self.assertEqual(plan,[('feature/additive',self.branch)])
        self.assertEqual(push_arguments(plan),['push','--atomic','--force-with-lease=refs/heads/feature/additive:'+self.branch,'origin',':refs/heads/feature/additive'])
    def test_changed_branch_blocks_entire_cleanup(self):
        self.heads['feature/additive']='d'*40
        with self.assertRaisesRegex(ValueError,'Branch moved'):self.plan()
    def test_new_branch_blocks_cleanup(self):
        self.heads['new-work']='d'*40
        with self.assertRaisesRegex(ValueError,'New branches'):self.plan()
    def test_changed_main_blocks_cleanup(self):
        self.heads['main']='d'*40
        with self.assertRaisesRegex(ValueError,'Main moved'):self.plan()
    def test_unmerged_head_blocks_cleanup(self):
        with self.assertRaisesRegex(ValueError,'not preserved'):self.plan(lambda a,b:False)
    def test_protected_names_cannot_be_deleted(self):
        self.manifest['branches'][0]['action']='delete-after-integration'
        with self.assertRaisesRegex(ValueError,'Protected branch'):self.plan()
    def test_existing_master_is_retained(self):
        self.heads['master']='d'*40
        self.assertEqual(len(self.plan()),1)
    def test_missing_branch_is_idempotent(self):
        del self.heads['feature/additive'];self.assertEqual(self.plan(),[])
    def test_wrong_anchor_is_rejected(self):
        self.manifest['integration_commit']='d'*40
        with self.assertRaisesRegex(ValueError,'anchor'):self.plan()
    def test_duplicate_manifest_entry_is_rejected(self):
        self.manifest['branches'].append(copy.deepcopy(self.manifest['branches'][1]))
        with self.assertRaisesRegex(ValueError,'duplicate'):self.plan()

if __name__=='__main__':unittest.main()
