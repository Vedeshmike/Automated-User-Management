@isTest
public class UserProvisioningControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Mock CMDT Data using Static Resources or SOQL Query

        // Create Sample Dynamic Rule
        Provisioning_Rule__c rule = new Provisioning_Rule__c(
            Name = 'Test Rule',
            Job_Title__c = 'Developer',
            Department__c = 'IT',
            Profile_Name__c = 'Standard User',
            Role_Name__c = 'Software Engineer',
            isActive__c = true
        );
        insert rule;

        // Create Sample Permission Set Assignment
        PermissionSet_Assignment__c psa = new PermissionSet_Assignment__c(
            Provisioning_Rule__c = rule.Id,
            Permission_Set_Id__c = '0PS1A0000001XYZ'  // Fake Permission Set ID for Testing
        );
        insert psa;

        // Create a Sample User
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser-' + System.currentTimeMillis() + '@example.com', // ✅ Unique username
            Alias = 'testuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = userProfile.Id,
            LanguageLocaleKey = 'en_US'
        );

        insert testUser;
    }

    // Test for Standard Rules Retrieval
   

    // Test for Dynamic Rules Retrieval
    @isTest
    static void testGetDynamicRules() {
        Test.startTest();
        List<Provisioning_Rule__c> rules = UserProvisioningController.getDynamicRules();
        Test.stopTest();

        System.assertEquals(1, rules.size(), 'Dynamic Rules should be fetched correctly');
    }

    // Test for Fetching Permission Sets
    @isTest
    static void testGetPermissionSets() {
        Test.startTest();
        List<Map<String, String>> permissionSets = UserProvisioningController.getPermissionSets();
        Test.stopTest();
        
        System.assertNotEquals(0, permissionSets.size(), 'Permission Sets should be fetched correctly');
    }

    // Test for Lookup Values
    @isTest
    static void testGetLookupValues() {
        Test.startTest();
        Map<String, List<Map<String, String>>> lookupValues = UserProvisioningController.getLookupValues();
        Test.stopTest();

        System.assertNotEquals(0, lookupValues.size(), 'Lookup values should be fetched!');
    }

    // Test for Saving Dynamic Rule
    @isTest
    static void testSaveDynamicRule() {
        // Mock test data
        String jobTitle = 'Test Engineer';
        String department = 'QA';
        String profileName = 'QA Profile';
        String roleName = 'QA Role';
        Boolean isActive = true;
        // Create fake Permission Set ID (for test context)
        String fakePSId = '0PS000000000001'; // 15-character dummy format
        String fakePSGId = '0PS000000001001';
        // Invoke method
        Test.startTest();
        UserProvisioningController.saveDynamicRule(
            jobTitle,
            department,
            profileName,
            roleName,
			new List<String>{ fakePSId },
            new List<String>{ fakePSGId },
            isActive
        );
        Test.stopTest();
        
        // Assert records were created
        List<Provisioning_Rule__c> rules = [SELECT Id FROM Provisioning_Rule__c WHERE Job_Title__c = :jobTitle];
        System.assertEquals(1, rules.size());
        
        List<PermissionSet_Assignment__c> psAssignments = [SELECT Id FROM PermissionSet_Assignment__c WHERE Provisioning_Rule__c = :rules[0].Id];
        System.assertEquals(2, psAssignments.size());
    }

}