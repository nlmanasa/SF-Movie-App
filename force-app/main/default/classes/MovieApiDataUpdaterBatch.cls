global class MovieApiDataUpdaterBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    String personUrl = 'https://api.themoviedb.org/3/person/';
    String apiKey = '42ee719896b25f8821890615eeabf17f';
    String movieUrl = 'https://api.themoviedb.org/3/movie/';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, TmdbId__c, (SELECT Actor_Name__c,  Actor_Name__r.Actor_Id__c FROM Casts__r) FROM Movie__c ]);
    }

    global void execute(Database.BatchableContext BC, List<Movie__c> scope) {
        List<Movie__c> moviesToUpdate = new List<Movie__c> ();
        List<Actor__c> actorsToUpdate = new List<Actor__c>();
        Map<Id, Actor__c> actorRecordMap = new Map<Id, Actor__c>();
        for (Movie__c movie : scope) {
            String moviePosterEndpoint = movieUrl + movie.TmdbId__c + '?api_key=' + apiKey;
            HttpResponse movieInfo = callTmdbApi(moviePosterEndpoint);

            if (movieInfo != null) {
                String moviePosterPath = parseMovieInfo(movieInfo);
                String imageUrl = 'https://image.tmdb.org/t/p/original';
                moviePosterPath = imageUrl + moviePosterPath;
                System.debug('Poster Path Response: ' + moviePosterPath);
                movie.posterUrl__c = moviePosterPath;
                moviesToUpdate.add(movie);
               

                for (Cast__c castMember : movie.Casts__r) {
                    String actorEndpoint = personUrl + castMember.Actor_Name__r.Actor_Id__c + '?api_key=' + apiKey;
                    HttpResponse actorInfo = callTmdbApi(actorEndpoint);

                    if (actorInfo != null) {
                        String actorImagePath = parseActorInfo(actorInfo);
                        System.debug(actorImagePath);
        
                        if (actorImagePath != null) {
                            //String imageUrl = 'https://image.tmdb.org/t/p/original';
                            actorImagePath = imageUrl + actorImagePath;
                            Actor__c actor = new Actor__c(Id = castMember.Actor_Name__r.Id);
                            actor.Actor_Poster_Url__c = actorImagePath;
                            actorRecordMap.put(castMember.Actor_Name__r.Id, actor);
                        }
                    }
                }
           }       
        }
        for( Id key: actorRecordMap.keyset()){
            actorsToUpdate.add(actorRecordMap.get(key));  
        }

        updateMovieRecord(moviesToUpdate);
        updateActorRecord(actorsToUpdate);
    }

    global void finish(Database.BatchableContext BC) {
    }

    private HttpResponse callTmdbApi(String endpoint) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            return response;
        } else {
            System.debug('API Call failed with status code: ' + response.getStatusCode());
            return null;
        }
    }

    private String parseMovieInfo(HttpResponse movieInfo) {
        if (movieInfo != null && String.isNotBlank(movieInfo.getBody())) {
            Map<String, Object> movieInfoMap = (Map<String, Object>) JSON.deserializeUntyped(movieInfo.getBody());
            String posterPath = (String) movieInfoMap.get('poster_path');
            return posterPath;
        }
        return null;
    }
    

    private String parseActorInfo(HttpResponse actorInfo) {
        if (actorInfo != null && String.isNotBlank(actorInfo.getBody())) {
            Map<String, Object> actorInfoMap = (Map<String, Object>) JSON.deserializeUntyped(actorInfo.getBody());
            String profilePath = (String) actorInfoMap.get('profile_path');
            
            if (profilePath != null) {
                return profilePath;
            }
        }
        return null;
    }

    private void updateMovieRecord(List<Movie__c> movies) {
        update movies;
    }

    private void updateActorRecord(List<Actor__c> actors) {
        update actors;
    }
}