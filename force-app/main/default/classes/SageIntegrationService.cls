public with sharing class SageIntegrationService {

    @future(callout=true)
    public static void postProject(String json) {
        System.debug(json);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://sage-api-proxy-zmqsyv.5sc6y6-1.usa-e2.cloudhub.io/project');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);

        HttpResponse res = new Http().send(req);
        System.debug(res.getBody());
        
        if (res.getStatusCode() != 201) {
            throw new CalloutException(res.getBody());
        }
    }

    @future(callout=true)
    public static void getProjects() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://sage-api-proxy-zmqsyv.5sc6y6-1.usa-e2.cloudhub.io/project');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');

        HttpResponse res = new Http().send(req);
        System.debug(res.getBody());
    }

    public static Boolean postInvoice(String invId) {
        InvoicePayload payload = new InvoicePayload();
        List<InvoiceLineItem> liList = new List<InvoiceLineItem>();

        Invoice__c inv = [
            SELECT 
                Id,
                Date__c,
                Due_Date__c,
                Description__c,
                Restrictions__c,
                Reference_Number__c,
                Customer__c,
                Customer__r.Customer_ID__c,
                (
                    SELECT
                        Amount__c,
                        Memo__c,
                        GL_Account__r.Account_Id__c,
                        Project__r.Location__c,
                        Project__r.Department__c,
                        Project__r.ProjectId__c
                    FROM
                        Invoice_Entries__r
                    WHERE 
                        Invoice__c = :invId
                )
            FROM
                Invoice__c
            WHERE
                Id = :invId
        ];

        for (Invoice_Entry__c ie : inv.Invoice_Entries__r) {
            InvoiceLineItem ili = new InvoiceLineItem();
            ili.amount = ie.Amount__c;
            ili.memo = ie.Memo__c;
            ili.glAccountNo = ie.GL_Account__r.Account_Id__c;
            ili.projectId = ie.Project__r.ProjectId__c;
            ili.locationId = ie.Project__r.Location__c;
            ili.departmentId = ie.Project__r.Department__c;
            ili.restrictionId = inv.Restrictions__c;
            liList.add(ili);
        }

        payload.salesforceId = inv.Id;
        payload.invoiceDate = inv.Date__c;
        payload.dueDate = inv.Due_Date__c;
        payload.description = inv.Description__c;
        payload.lineItem = liList;
        payload.customer = new SageCustomer(
            inv.Customer__c, 
            inv.Customer__r.Customer_ID__c
        );

        System.debug(JSON.serializePretty(payload));

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://sage-api-proxy-zmqsyv.5sc6y6-1.usa-e2.cloudhub.io/invoice');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serializePretty(payload));

        HttpResponse res = new Http().send(req);
        System.debug(res.getBody());
        
        if (res.getStatusCode() != 201) {
            Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            throw new CalloutException((String) resBody.get('message'));
        } 

        return true;
    }

    @future(callout=true)
    public static void getInvoices() {

        Mulesoft_Connector__mdt mc = [
            SELECT Id, LastCalloutDate__c 
            FROM Mulesoft_Connector__Mdt
            WHERE DeveloperName = 'Invoice'
        ];

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://sage-api-proxy-zmqsyv.5sc6y6-1.usa-e2.cloudhub.io/invoice?lastUpdate=' + mc.LastCalloutDate__c);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');

        HttpResponse res = new Http().send(req);
    } 

    public static Boolean postPayment(String payId) {
        System.debug(payId);
        Invoice_Payment__c pay = [
            SELECT
                Id,
                Amount__c,
                Date__c,
                Payment_Type__c,
                Notes__c,
                Invoice__r.Customer__r.Customer_ID__c,
                Invoice__r.SageRecId__c
            FROM Invoice_Payment__c
            WHERE Id = :payId
        ];

        PaymentPayload payload = new PaymentPayload();
        payload.salesforceId = pay.Id;
        payload.paymentMethod = pay.Payment_Type__c;
        payload.paymentDate = pay.Date__c;
        payload.description = pay.Notes__c;
        payload.currencyz = 'USD';
        payload.customerId = pay.Invoice__r.Customer__r.Customer_ID__c;
        payload.paymentDetail = new PaymentDetail(
            pay.Invoice__r.SageRecId__c,
            pay.Amount__c
        );

        System.debug(JSON.serializePretty(new Map<String, Object>{
            'salesforceId' => payload.salesforceId,
            'paymentMethod' => payload.paymentMethod,
            'paymentDate' => String.valueOf(payload.paymentDate),
            'description' => payload.description,
            'currency' => payload.currencyz,
            'customerId' => payload.customerId,
            'paymentDetail' => payload.paymentDetail
        }));

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://sage-api-proxy-zmqsyv.5sc6y6-1.usa-e2.cloudhub.io/payment');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serializePretty(new Map<String, Object>{
            'salesforceId' => payload.salesforceId,
            'paymentMethod' => payload.paymentMethod,
            'paymentDate' => String.valueOf(payload.paymentDate),
            'description' => payload.description,
            'currency' => payload.currencyz,
            'customerId' => payload.customerId,
            'paymentDetail' => payload.paymentDetail
        }));

        HttpResponse res = new Http().send(req);
        System.debug(res.getBody());
        
        if (res.getStatusCode() != 201) {
            Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            throw new CalloutException((String) resBody.get('message'));
        }  

        return true;
    }

    public class SageCustomer {
        public String salesforceId;
        public String customerId;

        public SageCustomer(String salesforceId, String customerId) {
            this.salesforceId = salesforceId;
            this.customerId = customerId;
        }
    }
    
    public class ProjectPayload {
        public String salesforceRecordId;
        public String projectId;
        public String projectName;
        public String projectCategory;
        public String projectType;
        public String projectStatus;
        public Boolean status;
        public String description;
        public Date startDate;
        public Date endDate;
        public String restrictionId;
        public String locationId;
        public String deptId;
        public SageCustomer customer;
    }

    public class InvoicePayload {
        public String salesforceId;
        public Date invoiceDate;
        public Date dueDate;
        public String terms;
        public String poNumber;
        public String description;
        public String billTo;
        public String shipTo;
        public SageCustomer customer;
        public InvoiceLineItem[] lineItem;
    }

    public class InvoiceLineItem {
        public String glAccountNo;
        public Decimal amount;
        public String memo;
        public String itemId;
        public String projectId;
        public String locationId;
        public String departmentId;
        public String restrictionId;
    }

    public class PaymentPayload {
        public String salesforceId;
        public String paymentMethod;
        public String customerId;
        public String description;
        public Date paymentDate;
        public String currencyz;
        public PaymentDetail paymentDetail;
    }

    public class PaymentDetail {
        public String sageInvoiceId;
        public Decimal amount;

        public PaymentDetail(String sageInvoiceId, Decimal amount) {
            this.sageInvoiceId = sageInvoiceId;
            this.amount = amount;
        }
    }
}