public with sharing class OpportunityService {
    
    public static void syncProject(List<Opportunity> oppList, Map<Id, Opportunity> oldOppMap) {
        String rtId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Grant' AND SObjectType = 'Opportunity'].Id;
        for (Opportunity opp : oppList) {
            if (opp.StageName == 'Closed Won' & 
                String.isEmpty(opp.ProjectId__c) & 
                oldOppMap.get(opp.Id).StageName != opp.StageName &
                opp.RecordTypeId == rtId) {
                Account acc = [
                    SELECT Id, Customer_ID__c 
                    FROM Account 
                    WHERE Id = :opp.AccountId
                ];

                SageIntegrationService.SageCustomer cust = new SageIntegrationService.SageCustomer(
                    acc.Id,
                    acc?.Customer_ID__c
                );

                SageIntegrationService.ProjectPayload proj = new SageIntegrationService.ProjectPayload();
                proj.salesforceRecordId = opp.Id;
                proj.projectName = opp.Name;
                proj.projectCategory = opp.ProjectCategory__c;
                proj.projectType = opp.ProjectType__c;
                proj.projectStatus = opp.ProjectStatus__c;
                proj.status = opp.Active__c;
                proj.description = opp.Description;
                proj.startDate = opp.Start_Date__c;
                proj.endDate = opp.EndDate__c;
                proj.restrictionId = opp.Restrictions__c;
                proj.locationId = opp.Location__c;
                proj.deptId = opp.Department__c;
                proj.customer = cust;

                // * MAKE CALLOUT
                SageIntegrationService.postProject(JSON.serializePretty(proj));
            }
        }
    }
}