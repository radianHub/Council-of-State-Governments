/**
 * @Class Name     : HttpResponseFactory
 * @Class Purpose  : SERVES AS DATA FACTORY FOR ALL YOUR HTTP RESPONSES
 * @Author         : Zachary Csotya
 * @Developed On   : 10/28/2023
 * @Last Modified  : 05/31/2024
**/
@isTest
public with sharing class HttpResponseFactory {
    
    /**
    * @description : CREATES AND RETURNS AN HTTP RESPONSE
    * @author Zachary Csotya | 10/28/2023 
    * @param Integer code 
    * @param String status 
    * @param String body 
    * @return HttpResponse 
    **/
    public static HttpResponse createHttpResponse(Integer code, String status, String body) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        res.setStatus(status);
        res.setStatusCode(code);

        return res;
    }

    public static HttpResponse postSuccess() {
        return createHttpResponse(201, 'Created', '');
    }

    public static HttpResponse postFailure() {
        String body = '{' +
            '"message": "bad request" ' +
        '}';

        return createHttpResponse(400, 'BAD_REQUEST', JSON.serialize(body));
    }

    public static HttpResponse getSuccess() {
        List<String> body = new List<String>{'123', '456', '789'}; 
        
        return createHttpResponse(200, 'OK', JSON.serialize(body));
    }

    public static HttpResponse getFailure() {
        String body = '{' +
            '"message": "resources not found", ' +
        '}';

        return createHttpResponse(404, 'NOT_FOUND', body);
    }
}