Task Default UpdateTags, RecentPosts, Build, Image

Task UpdateTags -Inputs (Get-Item "$psscriptroot\_posts\*.md") -Outputs "$psscriptroot\tags.md" {
    & "$psscriptroot\UpdateTags.ps1"
}

Task Image {
    & "$psscriptroot\CreateTitleImage.ps1"
}

Task RecentPosts -Inputs (Get-Item "$psscriptroot\_posts\*.md") -Outputs "$psscriptroot\_includes\recent-posts.md" {
    & "$psscriptroot\UpdateRecentPosts.ps1"
}

Task Build {
    # No -it so this also runs from scripts and CI. Run 'bundle update' by hand when you want newer gems.
    docker run --rm --volume=$($PSScriptRoot):/srv/jekyll --name blogbuilder jekyll/jekyll /bin/sh -c 'cd /srv/jekyll && bundle install && bundle exec jekyll build --source /srv/jekyll/. --destination /srv/jekyll/_site/.'
    if ($LASTEXITCODE -ne 0) { throw "Jekyll build failed with exit code [$LASTEXITCODE]" }
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