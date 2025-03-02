public without sharing class UserLicenseHelper {
    @AuraEnabled
    public static List<Map<String, Object>> getUserLicenseDetails() {
        List<Map<String, Object>> licenseList = new List<Map<String, Object>>();

        try {
            // Fetch User License details
            List<UserLicense> userLicenses = [SELECT Name, TotalLicenses, UsedLicenses FROM UserLicense];

            // Convert the data to JSON-compatible format
            for (UserLicense ul : userLicenses) {
                Map<String, Object> licenseMap = new Map<String, Object>();
                licenseMap.put('Name', ul.Name);
                licenseMap.put('TotalLicenses', ul.TotalLicenses);
                licenseMap.put('UsedLicenses', ul.UsedLicenses);
                licenseMap.put('AvailableLicenses', ul.TotalLicenses - ul.UsedLicenses);
                licenseList.add(licenseMap);
            }
				System.debug('@@UserLicenseHelper' +licenseList);

            return licenseList;
        } catch (Exception e) {
            System.debug('Error fetching User Licenses: ' + e.getMessage());
            return new List<Map<String, Object>>();  // Return empty list in case of an error
        }
    }
}