public with sharing class ParseJson {
	Static String fileName = 'moviesDataBoth'; 
	Static List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion
                                        WHERE Title = :fileName
                                        LIMIT 1];
 	Static String jsonFileId = contentVersions[0].ContentDocumentId;
	Static ContentVersion jsonFileText = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :jsonFileId AND IsLatest = true LIMIT 1];
	Static Blob jsonFileBody = jsonFileText.VersionData; 
	Static String jsonAsString= jsonFileBody.toString();
	static List<Movie> movies = new List<Movie>();
	static Set<Actor> actors = new Set<Actor>();
	public static void parse() {
		// Parse entire JSON response.
    JSONParser parser = JSON.createParser(jsonAsString);
    while (parser.nextToken() != null) {
		if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
			while (parser.nextToken() != null) {	
				if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
					Movie mov = (Movie)parser.readValueAs(Movie.class);
					parser.skipChildren();
					movies.add(mov);
					}
				}
			}
    }
		System.debug(movies);
        insertMovies();
		insertActors();
		insertCast();	
	}

	 public static void insertMovies() {
		List<Movie__c> movieRecords = new List<Movie__c>();
		for (Movie mov : movies) {
            Movie__c newMovieRecord = new Movie__c();
            newMovieRecord.name = mov.title;
            newMovieRecord.TmdbId__c =mov.tmdbId;
			newMovieRecord.Tagline__c = mov.tagline;
			newMovieRecord.Overview__c = mov.overview;
			newMovieRecord.ReleaseDate__c = Date.valueOf(mov.releaseDate);
			// Extract genres from the movie and concatenate them into a comma-separated string
			if (mov.genres != null && !mov.genres.isEmpty()) {
				List<String> genreNames = new List<String>();
				for (Genre genre : mov.genres) {
					genreNames.add(genre.name);
				}
				newMovieRecord.Genre_Name__c = String.join(genreNames, ';'); 
			}
			if(mov.originalLanguage == 'hi'){
				newMovieRecord.Is_Hindi_Movie__c = true;

			}
	
			movieRecords.add(newMovieRecord);
		
		}
        insert movieRecords;
	}
	public static void insertActors() {
		Map<String, String> actorRecordsMap =new  Map<String, String> ();
        List<Actor__c> actorRecordList = new List<Actor__c>();
		for (Movie mov : movies) {
            for (CastMember cm : mov.castMembers) {
                Actor__c newActorRecord = new Actor__c();
                newActorRecord.Name = cm.name;
                newActorRecord.Actor_Id__c = cm.id;
				actorRecordsMap.put(cm.id, cm.name );
			}
			
		}
        for(String key: actorRecordsMap.keySet()){
            Actor__c newActorRecord = new Actor__c();
			newActorRecord.Name =actorRecordsMap.get(key) ;
			newActorRecord.Actor_Id__c = key;
                actorRecordList.add(newActorRecord);
        }
        insert actorRecordList;
	}
public static void insertCast() {
		List<Cast__c> castRecords = new List<Cast__c>();
		for (Movie mov : movies) {
			for (CastMember cm : mov.castMembers) {
				
				Cast__c newCastRecord = new Cast__c();
				newCastRecord.Movie_Name__r = new Movie__c(TmdbId__c = mov.tmdbId);
				newCastRecord.Actor_Name__r = new Actor__c(Actor_Id__c = cm.id);
				newCastRecord.Character__c = cm.character;
				newCastRecord.Cast_Id__c = cm.castId;
		
				castRecords.add(newCastRecord);
			}
		}
	
		insert castRecords;
	}
	
	public class Movie {
		public String tmdbId;
        public List<Genre> genres;
		public String originalTitle;
		public String overview;
		public String releaseDate;
		public String tagline;
        public String title;
		public String  originalLanguage;
		public List<CastMember> castMembers;	
	}

	public class Genre{
		public String name;
	}

	public class CastMember {
		public String castId; 
		public String id;
		public String name;
        public string character;
	}
	public class Actor {
		public String id;
		public String name;	
	}
}