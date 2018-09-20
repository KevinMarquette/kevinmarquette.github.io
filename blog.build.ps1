Task Default UpdateTags, RecentPosts, Build, Image

Task UpdateTags -Inputs (Get-Item "$psscriptroot\_posts\*.md") -Outputs "$psscriptroot\tags.md" {
    .\UpdateTags.ps1
}

Task Image {
    .\CreateTitleImage.ps1
}

Task RecentPosts -Inputs (Get-Item "$psscriptroot\_posts\*.md") -Outputs "$psscriptroot\_includes\recent-posts.md" {
    .\UpdateRecentPosts.ps1
}

Task Build {
    docker run --rm -it --volume=$($PSScriptRoot):/srv/jekyll --name blogbuilder jekyll/jekyll /bin/sh -c 'cd /srv/jekyll; bundle update; bundle install; bundle exec jekyll build --source /srv/jekyll/. --destination /srv/jekyll/_site/.'
}

Task Run {
    'Starting container to host this site' 
    docker run --name bloghost --volume=$($PSScriptRoot)/_site:/usr/share/nginx/html:ro -d -p 8080:80 nginx
    'http://localhost:8080'
}

Task Stop {
    'Stopping container hosting blog on port 8080'
    docker rm bloghost -f
}

Task NewPost {
    & {Invoke-Plaster -DestinationPath $psscriptroot -TemplatePath $psscriptroot\..\PlasterTemplates\BlogPost }
}