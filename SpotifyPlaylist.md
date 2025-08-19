# Spotify Playlist

## Authorization (Phase 1)

### Two kinds of Oauth flows:

- **Authorization Code Flow**: This is a common and secure method to log in when we require authorization for ***user-specific data***. It redirects user to a Spotify Authorization page, which upon approval returns the user to our page with an authorization code which the app exchanges for an access token.

- **Client Credentials Flow**: This flow is used for server to server authentication where application accesses its own resources or public information, not user-specific data.

> Since here we require access to user data (playlists), we will go with ***Authorization code flow***.

### Redirect URI

- Since we have decided to use Authorization code flow, we need to add a **redirect URI**

- So firstly we need to log into our Developer Dashboard on Spotify and setup a Redirect URI

- Then we need to set this exact URI in our code so it knows where to locate
  
  <small>Note : The URI address cannot be localhost</small>

- We are going to use `http://127.0.0.1:8888/callback`.

## Code Flow (Phase 1)

### Setting up config.json

- Since we do not want to push the `CLIENT_ID` and `CLIENT_SECRET` to the repository, we will store it in a `config.json` file

```json
{
    "SPOTIFY":{
        "CLIENT_ID":"client-id",
        "CLIENT_SECRET":"client-secret",
        "REDIRECT_URI":"http://127.0.0.1:8888/callback"
    }
}
```

- Load this data using `json.load()`

- Then we use the `SpotifyOAuth()` funtion to setup these for later
  
  ```python
  auth_manager=SpotifyOAuth(
      client_id=CLIENT_ID,
      client_secret=CLIENT_SECRET,
      redirect_uri=REDIRECT_URI,
      scope=SCOPE
  ) 
  
  sp = spotipy.Spotify(auth_manager=auth_manager)
  ```

- refer to [Scopes | Spotify for Developers](https://developer.spotify.com/documentation/web-api/concepts/scopes) if required.

### Fetching Playlist ID

- The user is asked for an input in which the user can input one of these 3 inputs:
  
  - empty input which corresponds to Liked Songs playlist
  
  - playlist Name
  
  - playlist URL

- If the user gives playlist URL, we can splice an extract the ID from the URL itself
  
  ```python
  def id_helper_url(playlist_url:str)->str:
      return playlist_url[34:56]
  ```

- If the user provides the Playlist Name, we can get all the user playlists through `sp.get_current_user_playlists()` and then iterate and match the name to get ID
  
  > The above mentioned function will return a JSON object converted to dictionary by spotipy. We then iterate through `items` and implement a Fetch->Search->Repeat loop
  
  ```python
  def id_helper_name(playlist_name:str,sp=sp)->str:
      results = sp.current_user_playlists(limit=50)
      while True:
          if results['items']:
              for item in results['items']:
                  if 'name' in item and 'id' in item:
                      if item['name']==playlist_name:
                          return item['id']
          if results['next']:
              results = sp.next(results)
          else:
              return None
  ```

- If the user provides no input, we return an empty string which will be used later 

- If the name of playlist is not found, I am exiting for now but this can be modified later

- What is Pagination
  
  - Spotify Web API uses Pages of maximum 50 items for each API fetch.
  
  - If more than 50 objects exist in the fetched category,
    it will also provide the link to the next page, so we can continue looping and calling till we retrieve all pages.

### Playlist Track Fetching

- Once we have the id we can start fetching all the songs to extract the information.

- Two possibilities exist:
  
  - We have a playlist ID and use that to get the tracks
  
  - Playlist ID is an empty string and hence we fetch the saved songs

- I will be going with an approach where we fetch a page, extract required information and then fetch the next page.

- The attributes we are going to be fetching are defined in the constant list `ATTRIBUTES` which includes
  
  - `name`
  
  - `id`
  
  - `artists`
    
    - `name`
  
  - `album`
    
    - `name`
    
    - `album_type`
    
    - `release_date`
  
  - `duration_ms`

- I also wanted to add a behavior that if artists are fetched, they are split into primary artist and featured artist, hence I implemented it by separately handling them. Artists are also more difficult to handle as all other fetches return only a single item while this returns multiple possibly

```python
    output_columns=[]
    attribute_to_output_mapping=[]
    temp_idx_counter=0

    for attr in attributes:
        if attr == 'artists.name':
            output_columns.extend['primary-artist','featured-artists']
            attribute_to_output_mapping.append({'type': 'artists', 
                                                'original': attr, 
                                                'indices': (temp_idx_counter, temp_idx_counter + 1)})
            temp_idx_counter+=2
        else:
            output_columns.append(attr.replace('.','-'))
            attribute_to_output_mapping.append({'type':'other',
                                                'original':attr,
                                                'indices':temp_idx_counter})
            temp_idx_counter+=1
```

- The mapping info dictionary allows us to keep track of the corresponding info

- When handling `other` type of objects, we check wether attribute name has a `.` and if it does we split it and do a nested fetch by using two get operations. 

- This data is converted and returned as Dataframe

> Learned that when only specific objects have very different behavior , it becomes a pain to deal with. Probably should have converted the code to handle the artists into a function for better readability but its a one use thing so not doing that

### Exporting to excel

- Just using inbuilt function here. 

- I did need to install `openpyxl` for it though

```python
try:
    df.to_excel('spotify-data.xlsx', index=False) 
    print("DataFrame successfully saved to spotify-data.xlsx")
except Exception as e:
    print(f"Error saving DataFrame to Excel: {e}")
```

### Update Handling

- The Objective of the code was the ensure that songs removed from spotify aren't lost. So we can pass an update parameter which we can accept an older version of the excel version of playlist and merge the new one into it so the missing songs are not lost

- The missing and new songs are also showed in separate sheets so the user can manually review and based on the id, quickly search and remove the songs the user removed from playlist, rather than being removed by spotify 

- Using Set differences to see the changes

```python
def get_excel(df:pd.DataFrame,update:str=None):
    if update is None:
        try:
            df.to_excel('spotify-data.xlsx', index=False,sheet_name='AllSongs') 
            print("DataFrame successfully saved to spotify-data.xlsx")
        except Exception as e:
            print(f"Error saving DataFrame to Excel: {e}")
    else:
        old_df=pd.read_excel(update,sheet_name='AllSongs')
        old_track_id_series = old_df['id']
        new_track_id_series = df['id']
        old_ids_set = set(old_track_id_series)
        new_ids_set = set(new_track_id_series)
        missing_from_new_ids_set = old_ids_set - new_ids_set  
        newly_added_ids_set = new_ids_set - old_ids_set      
        missing_df=old_df[old_df['id'].isin(missing_from_new_ids_set)]
        newly_added_df=df[df['id'].isin(newly_added_ids_set)]
        if not missing_df.empty:
            main_df=pd.concat([df, missing_df], ignore_index=True)
        else:
            main_df=df.copy()
        output_path=update[:-5]+'-udpated'+'.xlsx'
        with pd.ExcelWriter(output_path) as writer:
            main_df.to_excel(writer,sheet_name='AllSongs',index=False)
            if not missing_df.empty:
                missing_df.to_excel(writer,sheet_name='missing-songs')
            else:
                df.to_excel(writer,sheet_name='missing-songs')
            if not newly_added_df.empty:
                newly_added_df.to_excel(writer,sheet_name='newly-added')
            else:
                df.to_excel(writer,sheet_name='newly-added')
```

## Possible Improvements

- We can specify the fields during the fetching operation, but I wanted to keep the code flexible at the cost of inefficiency as this is a very small scale project

- I need to check the feasibility of this to be converted in a front end based application

- Also I am being too reliant on the correctness of the API and spotify database, as I am not handling for `None` returns everywhere, for eg my double nested `.get` when fetching certain attributes for track (album).

- I am also using the current standard of spotify links to extract the URI, (This refers to the string splicing). I could use regex but again that would be relying on link pattern, but it would be more robust

- For very large playlist I may run into rate limits

----

## Authorization (Phase 2)

### What is PKCE and why to use it

- I want to package this into an app which can be publicly downloaded. 

- The issue with this is that for public clients, the `CLIENT_SECRET` cannot be securely stored within the app.

- But we need the `CLIENT_SECRET` as it is sent to prove identity when exchanging authorization code for an access token in the 'Authorization Code Flow'

- To solve this, thankfully Spotify API has implemented the PKCE (Proof Key for Code Exchange) that Oauth recommends

- PKCE adds an extra layer of security that doesn't rely on the `CLIENT_SECRET` being present on the client. The core idea is: 
  
  1. **The app creates a secret** random string called `code_verifier`.
  
  2. **The app creates a challenge**, a transformed (typically `SHA256` transformation followed by `base64url` encoding) to create a `code_challenge`. This is safe to send over potentially insecure channels.
  
  3. **Challenge is Sent to Spotify** when the user is redirected to authorization page along with `CLIENT_ID`,`SCOPE`,`REDIRECT_URI` and a parameter indicating the challenge method (in our case it is `SHA256`) .
  
  4. **User Authenticates, Gets Auth Code** which is sent back to the app's `REDIRECT_URI`.
  
  5. **App Exchanges Auth Code and Verifier for Tokens** which now acts as the earlier combination from Authorization flow of Auth Code and `CLIENT_SECRET`.
  
  6. **Spotify Verification** in which spotify takes the `code_verifier` , applies the same transformation to ensure that it matches with `code_challenge`.
  
  7. If they match, Spotify knows the client requesting tokens is the same one that initiated authorization. It then issues access and refreshes tokens.
  
  > My current confusion is that if an attacker intercepts step 3 and 5, they now have the challenge and the verifier, which together should be enough. My understanding is that the attacker would also need the auth code, which is short-lived, and if an attacker can get access to all of this, it means that the channel is highly compromised. So atleast in case of PKCE, the attacker would need to keep getting the dynamically generated high entropy code verifier over and over. 

*TLDR: A dynamically generated random string `code_verifier` acts as the `CLIENT_SECRET` bypassing the need to package it in the application.*

## Code Flow (Phase 2)

### Updating config.json

- We remove the `CLIENT_SECRET`
  
  ```json
  {
      "SPOTIFY":{
          "CLIENT_ID":"client-id",
          "REDIRECT_URI":"http://127.0.0.1:8888/callback"
      }
  }
  ```

- The `auth_manager` also has to be changed to try opening the browser.
  
  ```python
  auth_manager=SpotifyPKCE(
      client_id=CLIENT_ID,
      open_browser=True,
      redirect_uri=REDIRECT_URI,
      scope=SCOPE
  ) 
  ```

- I also call the `auth_manager.get_access_token()` to authenticate the user once

#### Very Important:

- The application is in development mode, so users need to be whitelisted to use the app using my credentials.

-----
