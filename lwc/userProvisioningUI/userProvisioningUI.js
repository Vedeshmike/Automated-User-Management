import { LightningElement, wire, track } from 'lwc';
import getLookupValues from '@salesforce/apex/UserProvisioningController.getLookupValues';
import getPermissionSets from '@salesforce/apex/UserProvisioningController.getPermissionSets';
import getPermissionSetsGroups from '@salesforce/apex/UserProvisioningController.getPermissionSetsGroups';
import saveDynamicRule from '@salesforce/apex/UserProvisioningController.saveDynamicRule';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UserProvisioningUI extends LightningElement {
    // Core data properties
    @track department = '';
    @track jobTitle = '';
    @track profileName = '';
    @track roleName = '';
    @track selectedPermissionSets = [];
    @track selectedPSGs = [];
    @track isActive = false;
    
    // UI control properties
    @track showHelpModal = false;
    @track loading = false;
    @track currentStep = '1';
    
    // Data collections
    @track permissionSets = [];
    @track permissionSetGroups = [];
    @track lookupOptions = { jobTitles: [], departments: [], profiles: [], roles: [] };
    
    // Computed properties
    get hasSelections() {
        const result = this.jobTitle && this.department && 
               (this.selectedPermissionSets.length > 0 || this.selectedPSGs.length > 0);
        console.log('🔍 hasSelections computed property:', result);
        console.log('  - jobTitle:', this.jobTitle);
        console.log('  - department:', this.department);
        console.log('  - selectedPermissionSets count:', this.selectedPermissionSets.length);
        console.log('  - selectedPSGs count:', this.selectedPSGs.length);
        return result;
    }
    
    get ruleSummary() {
        if (!this.hasSelections) return '';
        
        let summary = `This rule will assign `;
        
        // Count permissions
        const permCount = this.selectedPermissionSets.length;
        const psgCount = this.selectedPSGs.length;
        
        if (permCount > 0 && psgCount > 0) {
            summary += `${permCount} permission set${permCount > 1 ? 's' : ''} and ${psgCount} permission set group${psgCount > 1 ? 's' : ''}`;
        } else if (permCount > 0) {
            summary += `${permCount} permission set${permCount > 1 ? 's' : ''}`;
        } else if (psgCount > 0) {
            summary += `${psgCount} permission set group${psgCount > 1 ? 's' : ''}`;
        }
        
        summary += ` to users with job title "${this.jobTitle}" in the "${this.department}" department`;
        
        if (this.profileName) {
            summary += ` with profile "${this.profileName}"`;
        }
        
        if (this.roleName) {
            summary += ` and role "${this.roleName}"`;
        }
        
        summary += '.';
        
        console.log('📝 ruleSummary computed property:', summary);
        return summary;
    }
    
    get isSaveDisabled() {
        const result = !this.jobTitle || !this.department || 
              (this.selectedPermissionSets.length === 0 && this.selectedPSGs.length === 0);
        console.log('🔒 isSaveDisabled computed property:', result);
        console.log('  - jobTitle:', this.jobTitle);
        console.log('  - department:', this.department);
        console.log('  - selectedPermissionSets count:', this.selectedPermissionSets.length);
        console.log('  - selectedPSGs count:', this.selectedPSGs.length);
        return result;
    }
    
    // Wire services to fetch data
    @wire(getLookupValues)
    wiredLookupValues({ error, data }) {
        console.log('📥 Wire: getLookupValues executed');
        if (data) {
            console.log('✅ getLookupValues data received:', JSON.stringify(data));
            this.lookupOptions = data;
            this.loading = false;
        } else if (error) {
            console.error('❌ Error fetching lookup values', error);
            console.error('  - error message:', error.message);
            console.error('  - error body:', error.body);
            this.showErrorToast('Data Loading Error', 'Unable to load field values. Please refresh the page or contact your administrator.');
            this.loading = false;
        }
    }

    @wire(getPermissionSets)
    wiredPermissionSets({ error, data }) {
        console.log('📥 Wire: getPermissionSets executed');
        if (data) {
            console.log('✅ getPermissionSets data received, count:', data.length);
            this.permissionSets = data;
        } else if (error) {
            console.error('❌ Error fetching permission sets', error);
            console.error('  - error message:', error.message);
            console.error('  - error body:', error.body);
            this.showErrorToast('Data Loading Error', 'Unable to load permission sets. Please refresh the page or contact your administrator.');
        }
    }

    @wire(getPermissionSetsGroups)
    wiredPSGs({ error, data }) {
        console.log('📥 Wire: getPermissionSetsGroups executed');
        if (data) {
            console.log('✅ getPermissionSetsGroups data received, count:', data.length);
            this.permissionSetGroups = data;
        } else if (error) {
            console.error('❌ Error fetching PSGs', error);
            console.error('  - error message:', error.message);
            console.error('  - error body:', error.body);
            this.showErrorToast('Data Loading Error', 'Unable to load permission set groups. Please refresh the page or contact your administrator.');
        }
    }
    
    // Event handlers
    handleFieldChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        this[field] = value;
        
        console.log(`🔄 Field changed: ${field} = "${value}"`);
        
        // Update progress indicator based on field completion
        this.updateProgressIndicator();
    }

    handlePermissionSelect(event) {
        const previousValues = [...this.selectedPermissionSets];
        this.selectedPermissionSets = event.detail.value;
        
        console.log('🔄 Permission Sets selection changed');
        console.log('  - Previous selection:', JSON.stringify(previousValues));
        console.log('  - New selection:', JSON.stringify(this.selectedPermissionSets));
        console.log('  - Count:', this.selectedPermissionSets.length);
        
        this.updateProgressIndicator();
    }
    
    handlePSGSelect(event) {
        const previousValues = [...this.selectedPSGs];
        this.selectedPSGs = event.detail.value;
        
        console.log('🔄 Permission Set Groups selection changed');
        console.log('  - Previous selection:', JSON.stringify(previousValues));
        console.log('  - New selection:', JSON.stringify(this.selectedPSGs));
        console.log('  - Count:', this.selectedPSGs.length);
        
        this.updateProgressIndicator();
    }
    
    handleCheckboxChange(event) {
        const newValue = event.target.checked;
        console.log(`🔄 isActive changed: ${this.isActive} → ${newValue}`);
        this.isActive = newValue;
    }
    
    showHelp() {
        console.log('🔄 Help modal opened');
        this.showHelpModal = true;
    }
    
    closeHelp() {
        console.log('🔄 Help modal closed');
        this.showHelpModal = false;
    }
    
    // Update progress indicator based on completed sections
    updateProgressIndicator() {
        const previousStep = this.currentStep;
        
        if (this.jobTitle && this.department) {
            if (this.selectedPermissionSets.length > 0 || this.selectedPSGs.length > 0) {
                this.currentStep = '3'; // Review & Save
            } else {
                this.currentStep = '2'; // Assign Permissions
            }
        } else {
            this.currentStep = '1'; // Define Criteria
        }
        
        console.log(`🔄 Progress step updated: ${previousStep} → ${this.currentStep}`);
        console.log('  - jobTitle:', this.jobTitle);
        console.log('  - department:', this.department);
        console.log('  - selectedPermissionSets count:', this.selectedPermissionSets.length);
        console.log('  - selectedPSGs count:', this.selectedPSGs.length);
    }

    // Form actions
    handleSave() {
        console.log('🔄 Save button clicked');
        
        // Validate required fields
        if (this.isSaveDisabled) {
            console.warn('⚠️ Save validation failed - form incomplete');
            this.showErrorToast('Missing Information', 'Please complete all required fields and select at least one permission set or group.');
            return;
        }
        
        this.loading = true;
        console.log('📤 Sending saveDynamicRule with parameters:');
        console.log('  - jobTitle:', this.jobTitle);
        console.log('  - department:', this.department);
        console.log('  - profileName:', this.profileName);
        console.log('  - roleName:', this.roleName);
        console.log('  - permissionSetIds:', JSON.stringify(this.selectedPermissionSets));
        console.log('  - permissionSetGroupIds:', JSON.stringify(this.selectedPSGs));
        console.log('  - isActive:', this.isActive);
        
        saveDynamicRule({
            jobTitle: this.jobTitle,
            department: this.department,
            profileName: this.profileName,
            roleName: this.roleName,
            permissionSetIds: this.selectedPermissionSets,
            permissionSetGroupIds: this.selectedPSGs,
            isActive: this.isActive
        })
        .then(() => {
            console.log('✅ saveDynamicRule success');
            this.showSuccessToast('Success', 'User provisioning rule has been created and ' + 
                                  (this.isActive ? 'activated' : 'saved as inactive'));
            this.clearForm();
            this.loading = false;
        })
        .catch(error => {
            this.loading = false;
            console.error('🛑 Error saving dynamic rule:');
            console.error('👉 Full error object:', JSON.stringify(error, null, 2));
            console.error('🔍 error.body:', error.body);
            console.error('🔍 error.body.message:', error.body?.message);
            console.error('🔍 error.body.errorCode:', error.body?.errorCode);
            console.error('🔍 error.body.output:', error.body?.output);
            console.error('🔍 error.body.output.errors:', error.body?.output?.errors);
            console.error('🔍 error.body.output.fieldErrors:', error.body?.output?.fieldErrors);
        
            // Extract basic message
            const errorMessage = error.body?.message || error.message || 'Unknown error occurred';
        
            // Show error toast based on type
            if (errorMessage.includes('DUPLICATE_VALUE') || errorMessage.includes('duplicate')) {
                this.showErrorToast('Duplicate Rule', 'A rule with these criteria already exists. Please modify your criteria.');
            } else if (errorMessage.includes('ACCESS_DENIED') || errorMessage.includes('insufficient access')) {
                this.showErrorToast('Access Denied', 'You don\'t have permission to create this rule. Please contact your administrator.');
            } else if (errorMessage.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                this.showErrorToast('Validation Error', errorMessage);
            } else {
                this.showErrorToast('Error', 'Failed to save: ' + errorMessage);
            }
        });
    }

    clearForm() {
        console.log('🔄 Clearing form');
        this.department = '';
        this.jobTitle = '';
        this.profileName = '';
        this.roleName = '';
        this.selectedPermissionSets = [];
        this.selectedPSGs = [];
        this.isActive = false;
        this.currentStep = '1';
    }

    // Toast message helpers
    showSuccessToast(title, message) {
        console.log(`📢 Success toast: ${title} - ${message}`);
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success',
            mode: 'dismissable'
        }));
    }
    
    showErrorToast(title, message) {
        console.log(`📢 Error toast: ${title} - ${message}`);
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
            mode: 'dismissable'
        }));
    }
    
    // Lifecycle hooks
    connectedCallback() {
        console.log('🔄 Component initialized (connectedCallback)');
        this.loading = true;
    }
}