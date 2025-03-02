import { LightningElement, wire, track } from 'lwc';
import getLookupValues from '@salesforce/apex/UserProvisioningController.getLookupValues';
import getPermissionSets from '@salesforce/apex/UserProvisioningController.getPermissionSets';
import saveDynamicRule from '@salesforce/apex/UserProvisioningController.saveDynamicRule';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UserProvisioningUI extends LightningElement {
    @track department = '';
    @track jobTitle = '';
    @track profileName = '';
    @track roleName = '';
    @track selectedPermissionSets = [];
    @track isActive = false;
    
    @track permissionSets = [];
    @track lookupOptions = { jobTitles: [], departments: [], profiles: [], roles: [] };
    
    @wire(getLookupValues)
    wiredLookupValues({ error, data }) {
        if (data) {
            this.lookupOptions = data;
        } else if (error) {
            console.error('Error fetching lookup values', error);
        }
    }

    @wire(getPermissionSets)
    wiredPermissionSets({ error, data }) {
        if (data) {
            this.permissionSets = data;
        } else if (error) {
            console.error('Error fetching permission sets', error);
        }
    }

    handleFieldChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
    }

    handlePermissionSelect(event) {
        this.selectedPermissionSets = event.detail.value; // multi-select
    }

    handleSave() {
        if (!this.jobTitle || !this.department || this.selectedPermissionSets.length === 0) {
            console.log('@@' )
            this.showToast('Error', 'Please fill all required fields', 'error');
            return;
        }
        console.log('@@@' +this.jobTitle + this.department +this.profileName +this.roleName +this.selectedPermissionSets );
        saveDynamicRule({
            jobTitle: this.jobTitle,
            department: this.department,
            profileName: this.profileName,
            roleName: this.roleName,
            permissionSetIds: this.selectedPermissionSets,
            isActive: this.isActive
        })
        
        .then(() => {
            this.showToast('Success', 'Dynamic Rule Saved Successfully', 'success');
            this.clearForm();
            console.log('@@SAVED');
        })
        .catch(error => {
            console.error('Error saving dynamic rule', error);
            this.showToast('Error', 'Failed to save the rule, Check for Duplicate Records', 'error');
        });
    }

    clearForm() {
        this.department = '';
        this.jobTitle = '';
        this.profile = '';
        this.role = '';
        this.selectedPermissionSets = [];
    }
    handleCheckboxChange(event) {
        this.isActive = event.target.checked;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}