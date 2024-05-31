/**
 * @Class Name     : HttpResponseMatchers
 * @Class Purpose  : HOUSES ALL OF THE RESPONSE MATCHING CLASSES (1 CLASS PER RESPONSE)
 * @Author         : Zachary Csotya
 * @Developed On   : 10/28/2023
 * @Last Modified  : 05/31/2024
**/
@isTest
public with sharing class HttpResponseMatchers {

    public class PostMatcher implements HttpMatchingStrategy {
        public HttpResponse matchResponse(
            HttpRequest req,
            Map<String, HttpResponse> resStore,
            Boolean pass
        ) {
            if (req.getMethod() == 'POST') {
                if (pass) {
                    return resStore.get('postSuccess');
                }
                return resStore.get('postFailure'); 
            }
            return null;
        }
    }

    public class GetMatcher implements HttpMatchingStrategy {
        public HttpResponse matchResponse(
            HttpRequest req,
            Map<String, HttpResponse> resStore,
            Boolean pass
        ) {
            if (req.getMethod() == 'GET') {
                if (pass) {
                    return resStore.get('getSuccess');
                } 
                return resStore.get('getFailure');
            }
            return null;
        }
    }
}