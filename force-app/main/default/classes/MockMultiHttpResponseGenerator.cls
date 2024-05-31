/**
 * @Class Name     : MockMultiHttpResponseGenerator
 * @Class Purpose  : GENERATES A MOCK RESPONSE FOR AN HTTP REQUEST
 * @Author         : Zachary Csotya
 * @Developed On   : 10/28/2023
 * @Last Modified  : 05/31/2024
**/
@isTest
public with sharing class MockMultiHttpResponseGenerator implements HttpCalloutMock {
    private Map<String, HttpResponse> responseStore;
    private List<HttpMatchingStrategy> responseMatchers;
    private Boolean pass;

    /**
    * @description : (CONSTRUCTOR) INITIALIZES A MockMultiHttpResponseGenerator CLASS
    * @author Zachary Csotya | 10/28/2023 
    * @param Map<String HttpResponse> responseStore 
    * @param List<HttpMatchingStrategy> responseMatchers 
    * @param Boolean pass 
    * @param Boolean failOnAuth 
    **/
    public MockMultiHttpResponseGenerator(
        Map<String, HttpResponse> responseStore,
        List<HttpMatchingStrategy> responseMatchers, 
        Boolean pass) {
        this.responseStore = responseStore;
        this.responseMatchers = responseMatchers;
        this.pass = pass;
    }

    /**
    * @description : MATCHES A REQUEST WITH AN APPROPRIATE RESPONSE
    * @author Zachary Csotya | 10/28/2023 
    * @param HttpRequest req 
    * @return HttpResponse 
    **/
    private HttpResponse matchResponse(HttpRequest req) {
        HttpResponse res;
        for (HttpMatchingStrategy matcher : responseMatchers) {
            res = matcher.matchResponse(req, responseStore, pass);
            if (res != null) {
                break;
            }
        }
        return res;
    }

    /**
    * @description : RESPONDS TO AN HTTP REQUEST
    * @author Zachary Csotya | 10/28/2023 
    * @param HttpRequest req 
    * @return HttpResponse 
    **/
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = matchResponse(req);
        if (res == null) {
            System.assert(false, 'No response found for request.');
        }
        return res;
    }
}