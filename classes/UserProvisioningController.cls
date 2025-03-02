public without sharing class UserProvisioningController {
    
    // Fetch Standard Rules (Custom Metadata)
    @AuraEnabled(cacheable=true)
    public static List<User_Provisioning_Rule__mdt> getStandardRules() {
        return [SELECT DeveloperName, Job_Title__c, Department__c, Profile_Name__c, 
                Role_Name__c, Permission_Set__c, isActive__c
                FROM User_Provisioning_Rule__mdt];
    }
    
    // Fetch Dynamic Rules (Custom Object)
    @AuraEnabled(cacheable=true)
    public static List<Provisioning_Rule__c> getDynamicRules() {
        return [SELECT Id, Name, Job_Title__c, Department__c, Profile_Name__c, 
                Role_Name__c, isActive__c, 
                (SELECT Id, Name FROM PermissionSet_Assignments__r)
                FROM Provisioning_Rule__c];
    }
    
    // Fetch Permission Sets from Salesforce
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPermissionSets() {
        List<Map<String, String>> permissionSetList = new List<Map<String, String>>();
        
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE IsCustom = TRUE]) {
            permissionSetList.add(new Map<String, String>{'label' => ps.Name, 'value' => ps.Id});
        }
        
        System.debug('@@Permission Sets: ' + permissionSetList);
        return permissionSetList;
    }
    
    
    // Save Dynamic Rule
    // @AuraEnabled(cacheable=true)
    // public static Map<String, List<String>> getLookupValues() {
    //     Map<String, List<String>> lookupData = new Map<String, List<String>>();
    
    //     Set<String> jobTitleSet = new Set<String>();  
    //     Set<String> departmentSet = new Set<String>();  
    //     Set<String> profileSet = new Set<String>();  
    //     Set<String> roleSet = new Set<String>();  
    
    //     try {
    //         for (User userRec : [SELECT Title, Department, Profile.Name, UserRole.Name FROM User 
    //                              WHERE Title != NULL OR Department != NULL OR ProfileId != NULL OR UserRoleId != NULL]) {
    //                                  if (userRec.Title != null) {
    //                                      jobTitleSet.add(userRec.Title);
    //                                  }
    //                                  if (userRec.Department != null) {
    //                                      departmentSet.add(userRec.Department);
    //                                  }
    //                                  if (userRec.Profile != null && userRec.Profile.Name != null) {
    //                                      profileSet.add(userRec.Profile.Name);
    //                                  }
    //                                  if (userRec.UserRole != null && userRec.UserRole.Name != null) {
    //                                      roleSet.add(userRec.UserRole.Name);
    //                                  }
    //                              }
    
    //         // Convert Set to List before returning
    //         lookupData.put('jobTitles', new List<String>(jobTitleSet));
    //         lookupData.put('departments', new List<String>(departmentSet));
    //         lookupData.put('profiles', new List<String>(profileSet));
    //         lookupData.put('roles', new List<String>(roleSet));
    
    //         System.debug('@@lookupData' +lookupData);
    
    //     } catch (Exception e) {
    //         System.debug('Error fetching lookup values: ' + e.getMessage());
    //     }
    
    //     return lookupData;
    // }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getLookupValues() {
        Map<String, List<Map<String, String>>> lookupData = new Map<String, List<Map<String, String>>>();
        
        List<Map<String, String>> jobTitleList = new List<Map<String, String>>();
        List<Map<String, String>> departmentList = new List<Map<String, String>>();
        List<Map<String, String>> profileList = new List<Map<String, String>>();
        List<Map<String, String>> roleList = new List<Map<String, String>>();
        
        Set<String> jobTitleSet = new Set<String>();
        Set<String> departmentSet = new Set<String>();
        Set<String> profileSet = new Set<String>();
        Set<String> roleSet = new Set<String>();
        
        try {
            for (User userRec : [SELECT Title, Department, Profile.Name, UserRole.Name FROM User 
                                 WHERE Title != NULL OR Department != NULL OR ProfileId != NULL OR UserRoleId != NULL]) {
                                     if (userRec.Title != null) jobTitleSet.add(userRec.Title);
                                     if (userRec.Department != null) departmentSet.add(userRec.Department);
                                     if (userRec.Profile != null && userRec.Profile.Name != null) profileSet.add(userRec.Profile.Name);
                                     if (userRec.UserRole != null && userRec.UserRole.Name != null) roleSet.add(userRec.UserRole.Name);
                                 }
            
            // Convert Sets into Label-Value Lists
            for (String job : jobTitleSet) {
                jobTitleList.add(new Map<String, String>{'label' => job, 'value' => job});
            }
            for (String dept : departmentSet) {
                departmentList.add(new Map<String, String>{'label' => dept, 'value' => dept});
            }
            for (String profile : profileSet) {
                profileList.add(new Map<String, String>{'label' => profile, 'value' => profile});
            }
            for (String role : roleSet) {
                roleList.add(new Map<String, String>{'label' => role, 'value' => role});
            }
            
            lookupData.put('jobTitles', jobTitleList);
            lookupData.put('departments', departmentList);
            lookupData.put('profiles', profileList);
            lookupData.put('roles', roleList);
            
            System.debug('@@lookupData: ' + lookupData);
            
        } catch (Exception e) {
            System.debug('Error fetching lookup values: ' + e.getMessage());
        }
        
        return lookupData;
    }
    
    

      @AuraEnabled
    public static void saveDynamicRule(String jobTitle, String department, String profileName, String roleName, List<String> permissionSetIds) {
        try {
            if (String.isBlank(jobTitle) || String.isBlank(department) || permissionSetIds.isEmpty()) {
                throw new AuraHandledException('Job Title, Department, and at least one Permission Set are required.');
            }

            // Create the Dynamic Rule
            Provisioning_Rule__c newRule = new Provisioning_Rule__c();
            newRule.Job_Title__c = jobTitle;
            newRule.Department__c = department;
            newRule.Profile_Name__c = profileName;
            newRule.Role_Name__c = roleName;
            insert newRule;

            // Assign Permission Sets to Rule
            List<PermissionSet_Assignment__c> assignments = new List<PermissionSet_Assignment__c>();
            for (String permissionSetId : permissionSetIds) {
                PermissionSet_Assignment__c assignment = new PermissionSet_Assignment__c();
                assignment.Provisioning_Rule__c = newRule.Id;
                assignment.Permission_Set_Id__c = permissionSetId;
                assignments.add(assignment);
            }
            insert assignments;

        } catch (Exception e) {
            throw new AuraHandledException('Error saving dynamic rule: ' + e.getMessage());
        }
    }
    
    
}