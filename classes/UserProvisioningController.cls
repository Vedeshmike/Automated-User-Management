/**
 * Controller class for managing dynamic user provisioning rules.
 * - Fetches rules, permission sets, permission set groups, and lookup values.
 * - Supports creating new provisioning rules with associated permission sets/groups.
 */
public without sharing class UserProvisioningController {
    
    private static final String DEBUG_PREFIX = '🔍 [UserProvisioning] ';
    
    // Fetch Dynamic Rules (Custom Object)
    @AuraEnabled(cacheable=true)
    public static List<Provisioning_Rule__c> getDynamicRules() {
        System.debug(DEBUG_PREFIX + 'Getting dynamic rules');
        
        List<Provisioning_Rule__c> rules = [SELECT Id, Name, Job_Title__c, Department__c, Profile_Name__c, 
                Role_Name__c, isActive__c, 
                (SELECT Id, Name FROM PermissionSet_Assignments__r)
                FROM Provisioning_Rule__c];
        
        System.debug(DEBUG_PREFIX + 'Retrieved ' + rules.size() + ' provisioning rules');
        return rules;
    }
    
    // Fetch Permission Sets from Salesforce getPermissionSets
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPermissionSets() {
        System.debug(DEBUG_PREFIX + 'Fetching permission sets');
        
        List<Map<String, String>> permissionSetList = new List<Map<String, String>>();
        
        List<PermissionSet> permSets = [SELECT Id, Name 
                                         FROM PermissionSet 
                                         WHERE IsCustom = TRUE 
                                         AND CreatedBy.Name != 'Automated Process' 
                                         AND (NamespacePrefix = '' OR NamespacePrefix = null) 
                                         ORDER BY CreatedDate DESC];
        
        System.debug(DEBUG_PREFIX + 'Query returned ' + permSets.size() + ' permission sets');
        
        for (PermissionSet ps : permSets) {
            Map<String, String> psMap = new Map<String, String>{
                'label' => ps.Name, 
                'value' => ps.Id
            };
            permissionSetList.add(psMap);
            System.debug(DEBUG_PREFIX + 'Added permission set: ' + ps.Name + ' (' + ps.Id + ')');
        }
        
        System.debug(DEBUG_PREFIX + 'Returning ' + permissionSetList.size() + ' permission sets');
        return permissionSetList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPermissionSetsGroups() {
        System.debug(DEBUG_PREFIX + 'Fetching permission set groups');
        
        List<Map<String, String>> psgList = new List<Map<String, String>>();
        
        List<PermissionSetGroup> permSetGroups = [
            SELECT Id, DeveloperName 
            FROM PermissionSetGroup 
            ORDER BY CreatedDate DESC
        ];
        
        System.debug(DEBUG_PREFIX + 'Query returned ' + permSetGroups.size() + ' permission set groups');
        
        for (PermissionSetGroup psg : permSetGroups) {
            Map<String, String> psgMap = new Map<String, String>{
                'label' => psg.DeveloperName,
                'value' => psg.Id
            };
            psgList.add(psgMap);
            System.debug(DEBUG_PREFIX + 'Added permission set group: ' + psg.DeveloperName + ' (' + psg.Id + ')');
        }
        
        System.debug(DEBUG_PREFIX + 'Returning ' + psgList.size() + ' permission set groups');
        return psgList;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getLookupValues() {
        System.debug(DEBUG_PREFIX + 'Fetching lookup values');
        
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
            System.debug(DEBUG_PREFIX + 'Querying User records for lookup values');
            
            List<User> users = [SELECT Title, Department, Profile.Name, UserRole.Name FROM User 
                                 WHERE Title != NULL OR Department != NULL OR ProfileId != NULL OR UserRoleId != NULL];
            
            System.debug(DEBUG_PREFIX + 'Found ' + users.size() + ' user records with relevant fields');
            
            for (User userRec : users) {
                if (userRec.Title != null) {
                    jobTitleSet.add(userRec.Title);
                    System.debug(DEBUG_PREFIX + 'Added job title: ' + userRec.Title);
                }
                if (userRec.Department != null) {
                    departmentSet.add(userRec.Department);
                    System.debug(DEBUG_PREFIX + 'Added department: ' + userRec.Department);
                }
                if (userRec.Profile != null && userRec.Profile.Name != null) {
                    profileSet.add(userRec.Profile.Name);
                    System.debug(DEBUG_PREFIX + 'Added profile: ' + userRec.Profile.Name);
                }
                if (userRec.UserRole != null && userRec.UserRole.Name != null) {
                    roleSet.add(userRec.UserRole.Name);
                    System.debug(DEBUG_PREFIX + 'Added role: ' + userRec.UserRole.Name);
                }
            }
            
            System.debug(DEBUG_PREFIX + 'Unique values found - Job Titles: ' + jobTitleSet.size() + 
                        ', Departments: ' + departmentSet.size() + 
                        ', Profiles: ' + profileSet.size() + 
                        ', Roles: ' + roleSet.size());
            
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
            
            System.debug(DEBUG_PREFIX + 'Prepared lookup data with sizes - ' +
                        'Job Titles: ' + jobTitleList.size() + 
                        ', Departments: ' + departmentList.size() + 
                        ', Profiles: ' + profileList.size() + 
                        ', Roles: ' + roleList.size());
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, DEBUG_PREFIX + 'Error fetching lookup values: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, DEBUG_PREFIX + 'Stack trace: ' + e.getStackTraceString());
        }
        
        return lookupData;
    }
    
    @AuraEnabled
    public static void saveDynamicRule(String jobTitle, String department, String profileName, 
                                      String roleName, List<String> permissionSetIds, 
                                      List<String> permissionSetGroupIds, Boolean isActive) {
        System.debug(DEBUG_PREFIX + '==== SAVE DYNAMIC RULE - START ====');
        System.debug(DEBUG_PREFIX + 'Input Parameters:');
        System.debug(DEBUG_PREFIX + '- jobTitle: ' + (String.isBlank(jobTitle) ? '[BLANK]' : jobTitle));
        System.debug(DEBUG_PREFIX + '- department: ' + (String.isBlank(department) ? '[BLANK]' : department));
        System.debug(DEBUG_PREFIX + '- profileName: ' + (String.isBlank(profileName) ? '[NULL/BLANK]' : profileName));
        System.debug(DEBUG_PREFIX + '- roleName: ' + (String.isBlank(roleName) ? '[NULL/BLANK]' : roleName));
        System.debug(DEBUG_PREFIX + '- isActive: ' + isActive);
        
        if (permissionSetIds != null) {
            System.debug(DEBUG_PREFIX + '- permissionSetIds: ' + permissionSetIds.size() + ' items');
            for (Integer i = 0; i < permissionSetIds.size(); i++) {
                System.debug(DEBUG_PREFIX + '  [' + i + ']: ' + permissionSetIds[i]);
            }
        } else {
            System.debug(DEBUG_PREFIX + '- permissionSetIds: NULL');
        }
        
        if (permissionSetGroupIds != null) {
            System.debug(DEBUG_PREFIX + '- permissionSetGroupIds: ' + permissionSetGroupIds.size() + ' items');
            for (Integer i = 0; i < permissionSetGroupIds.size(); i++) {
                System.debug(DEBUG_PREFIX + '  [' + i + ']: ' + permissionSetGroupIds[i]);
            }
        } else {
            System.debug(DEBUG_PREFIX + '- permissionSetGroupIds: NULL');
        }
        
        try {
            // Validate input parameters
            Boolean noPS = (permissionSetIds == null || permissionSetIds.isEmpty());
            Boolean noPSG = (permissionSetGroupIds == null || permissionSetGroupIds.isEmpty());
            
            System.debug(DEBUG_PREFIX + 'Validation - No Permission Sets: ' + noPS);
            System.debug(DEBUG_PREFIX + 'Validation - No Permission Set Groups: ' + noPSG);
            
            if (String.isBlank(jobTitle) || String.isBlank(department) || (noPS && noPSG)) {
                String errorMsg = 'Job Title, Department, and at least one Permission Set or Permission Set Group is required.';
                System.debug(LoggingLevel.ERROR, DEBUG_PREFIX + 'Validation Error: ' + errorMsg);
                throw new AuraHandledException(errorMsg);
            }
            
            // ✅ Step 1: Check if a rule already exists
            System.debug(DEBUG_PREFIX + 'Checking for existing rules with same criteria');
            
            List<Provisioning_Rule__c> existingRules = [SELECT Id FROM Provisioning_Rule__c 
                                                        WHERE Job_Title__c = :jobTitle 
                                                        AND Department__c = :department 
                                                        AND Profile_Name__c = :profileName 
                                                        AND Role_Name__c = :roleName
                                                        LIMIT 1];
            
            System.debug(DEBUG_PREFIX + 'Existing rules found: ' + existingRules.size());
            
            if (!existingRules.isEmpty()) {
                String errorMsg = 'A rule with the same Job Title, Department, Profile, and Role already exists.';
                System.debug(LoggingLevel.ERROR, DEBUG_PREFIX + 'Duplicate Rule Error: ' + errorMsg);
                throw new AuraHandledException(errorMsg);
            }
            
            // ✅ Step 2: Insert new rule only if it doesn't exist
            System.debug(DEBUG_PREFIX + 'Creating new provisioning rule');
            
            Provisioning_Rule__c newRule = new Provisioning_Rule__c();
            newRule.Job_Title__c = jobTitle;
            newRule.Department__c = department;
            newRule.Profile_Name__c = profileName;
            newRule.Role_Name__c = roleName;
            newRule.isActive__c = isActive;
            
            System.debug(DEBUG_PREFIX + 'Inserting new rule with values:');
            System.debug(DEBUG_PREFIX + '- Job_Title__c: ' + newRule.Job_Title__c);
            System.debug(DEBUG_PREFIX + '- Department__c: ' + newRule.Department__c);
            System.debug(DEBUG_PREFIX + '- Profile_Name__c: ' + newRule.Profile_Name__c);
            System.debug(DEBUG_PREFIX + '- Role_Name__c: ' + newRule.Role_Name__c);
            System.debug(DEBUG_PREFIX + '- isActive__c: ' + newRule.isActive__c);
            
            insert newRule;
            System.debug(DEBUG_PREFIX + 'Successfully inserted rule with ID: ' + newRule.Id);
            
            // ✅ Step 3: Insert related Permission Set Assignments
            List<PermissionSet_Assignment__c> assignments = new List<PermissionSet_Assignment__c>();
            
            if (permissionSetIds != null && !permissionSetIds.isEmpty()) {
                System.debug(DEBUG_PREFIX + 'Creating ' + permissionSetIds.size() + ' permission set assignments');
                
                for (String psId : permissionSetIds) {
                    PermissionSet_Assignment__c psa = new PermissionSet_Assignment__c(
                        Provisioning_Rule__c = newRule.Id,
                        Permission_Set_Id__c = psId
                    );
                    assignments.add(psa);
                    System.debug(DEBUG_PREFIX + 'Added permission set assignment for PS ID: ' + psId +psa);
                }
            }
            
            if (permissionSetGroupIds != null && !permissionSetGroupIds.isEmpty()) {
                System.debug(DEBUG_PREFIX + 'Creating ' + permissionSetGroupIds.size() + ' permission set group assignments');
                
                for (String psgId : permissionSetGroupIds) {
                    PermissionSet_Assignment__c psa = new PermissionSet_Assignment__c(
                        Provisioning_Rule__c = newRule.Id,
                        Permission_Set_Group_Id__c = psgId
                    );
                    assignments.add(psa);
                    System.debug(DEBUG_PREFIX + 'Added permission set group assignment for PSG ID: ' + psgId +psa);
                }
            }
            
            if (!assignments.isEmpty()) {
                try {
                    System.debug(LoggingLevel.INFO, DEBUG_PREFIX + 'Inserting ' + assignments.size() + ' permission set assignments');
                    insert assignments;
                    System.debug(LoggingLevel.INFO, DEBUG_PREFIX + 'Successfully inserted ' + assignments.size() + ' permission set assignments');
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, DEBUG_PREFIX + 'Error inserting permission set assignments: ' + e.getMessage());
                    throw e;
                }
            } else {
                System.debug(LoggingLevel.INFO, DEBUG_PREFIX + 'No permission set assignments to insert');
            }
            
            System.debug(LoggingLevel.INFO, DEBUG_PREFIX + '==== SAVE DYNAMIC RULE - SUCCESS ====');
        } catch (AuraHandledException e) {
            System.debug(LoggingLevel.ERROR, DEBUG_PREFIX + 'AuraHandledException: ' + e.getMessage());
            throw e; // Rethrow to preserve the original message
        } catch (Exception e) {
            String errorMsg = 'Error saving dynamic rule: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, DEBUG_PREFIX + 'Exception occurred: ' + errorMsg);
            System.debug(LoggingLevel.ERROR, DEBUG_PREFIX + 'Stack trace: ' + e.getStackTraceString());
            System.debug(DEBUG_PREFIX + '==== SAVE DYNAMIC RULE - FAILED ====');
            throw new AuraHandledException(errorMsg);
        }
    }
}