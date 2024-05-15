public with sharing class PaymentProcessorController {

    @AuraEnabled(cacheable=true)
    public static Payment_Processor__c getSettings() {
        return Payment_Processor__c.getOrgDefaults();
    }

    @AuraEnabled(cacheable=true)
    public static Contact getUserContact(String id) {
        User u = [SELECT ContactId FROM User WHERE Id = :id];
        return [
            SELECT
                Id, 
                FirstName,
                LastName, 
                Account.Name, 
                Phone, 
                Email, 
                MailingStreet,
                MailingCity, 
                MailingState, 
                MailingPostalCode
            FROM
                Contact
            WHERE 
                Id = :u.ContactId 
        ];
    }

    // * SUCCESSFUL DONATION
    @AuraEnabled
    public static void successfulPayment(String processor, String contactId, String json) {
        if (processor == 'Auth.net') {
            AuthNetResponse data = AuthNetResponse.parseJSON(json);
            System.debug(data);

            Contact payee = new Contact(
                FirstName = data.FirstName,
                LastName = data.LastName,
                Email = data.Email,
                Phone = data.Phone,
                MailingStreet = data.Street,
                MailingCity = data.City,
                MailingState = data.State,
                MailingPostalCode = data.Zip,
                Id = contactId
            );
            upsert payee;

            Contact honoree;
            if (data.detail.isHonoree) {
                honoree = new Contact(
                    FirstName = data.detail.honoree.FirstName,
                    LastName = data.detail.honoree.LastName,
                    Phone = data.detail.honoree.Phone,
                    Email = data.detail.honoree.Email,
                    MailingStreet = data.detail.honoree.Street,
                    MailingCity = data.detail.honoree.City,
                    MailingState = data.detail.honoree.State,
                    MailingPostalCode = data.detail.honoree.Zip
                );
                insert honoree;
            }

            // TODO: WHAT SAGE FIELDS NEED TO BE SET?
            // TODO: RECORD TYPE?
            Opportunity donation = new Opportunity(
                Name = String.format(
                    '{0} ({1} {2}) Donation - {3}', 
                    new String[]{
                        data.Company, 
                        data.FirstName, 
                        data.LastName, 
                        data.detail.recurringInterval.startDate.format()
                    }
                ),
                AccountId = [SELECT AccountId FROM Contact WHERE Id = :payee.Id].AccountId,
                CloseDate = data.detail.recurringInterval.startDate,
                StageName = 'Closed Won',
                Amount = data.detail.amount
            );
            insert donation;

            OpportunityContactRole payeeRole = new OpportunityContactRole(
                ContactId = payee.Id,
                OpportunityId = donation.Id,
                IsPrimary = true
            );
            
            OpportunityContactRole honoreeRole;
            if (data.detail.isHonoree) {
                honoreeRole = new OpportunityContactRole(
                    ContactId = honoree.Id,
                    OpportunityId = donation.Id
                );  
            }            
            insert new OpportunityContactRole[]{payeeRole, honoreeRole};

            // TODO: CREATE INVOICE
            // TODO: CREATE PAYMENT
            // TODO: SEND TO SAGE
        }
    }

}