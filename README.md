Levelfly
========

![Levelfly logo](public/images/levelfly_tag.png?raw=true)

[![Build Status](https://drone.neuronicgames.com/api/badges/neuronic-games/levelfly/status.svg?ref=refs/heads/staging)](https://drone.neuronicgames.com/neuronic-games/levelfly)

Levelfly is an open-source, achievement-based Learning Management System (LMS) and social network, developed by [Neuronic Games][neuronic] for [Borough of Manhattan Community College][bmcc] and [City University of New York][cuny] with funding from the [National Science Foundation][nsf] and the [U.S. Department of Education][us-doe].

A demonstration instance of Levelfly is available at https://levelfly-staging.herokuapp.com

## Working on Levelfly

These instructions have been tested on Linux & OSX. If you can add set-up instructions for any other platform, or for tools like Docker or Vagrant, please [edit this README][editreadme] and share your wisdom!

1. Install [Postgres][postgres], and Ruby 2.4.10 ([RVM][rvm] is recommended)
2. Check out the Levelfly code:
    ```
    git clone https://github.com/neuronic-games/levelfly.git && cd levelfly
    ```
3. Create a Postgres database:
   ```
   createdb -U postgres levelfly
   ```
4. Edit `config/database.yml` to set your database username and password
5. Initialise the database:
    ```
    bundle exec rake db:create
    bundle exec rake db:migrate
    bundle exec rake db:seed
    ```
6. Set up S3 storage – either sign up for [AWS][aws-s3] or set up [minio][minio]. Then, edit `config/application.yml` to pop in your S3 API key
7. Install [MailCatcher][mailcatcher] to display outgoing mail in a browser instead of sending it:
    ```
    gem install mailcatcher
    mailcatcher
    ```
8. Run the server and job workers:
    ```
    bundle exec jobs:work &
    rails s
    ```

## Deploying Levelfly

Levelfly is pre-configured to deploy to [Heroku][heroku] using [Drone][drone].

If you're a project collaborator, just push to the `main` or `staging` branches,
and Drone will automatically deploy your code to the right server.

You can see the status of deployments here:

https://drone.neuronicgames.com/neuronic-games/levelfly

### Tagging a new release

1. Commit your changes to the `dev` branch
2. Edit `config/environment.rb`, increase `APP_VERSION`, and commit that change
   too
3. `git checkout main`
4. `git merge dev --no-ff`
5. `git tag -a <version>`

[neuronic]: https://neuronicgames.com
[bmcc]: https://www.bmcc.cuny.edu/
[cuny]: http://www.cuny.edu/
[nsf]: https://nsf.gov
[us-doe]: http://www.nsf.gov/
[editreadme]: https://github.com/neuronic-games/levelfly/edit/main/README.md
[rvm]: https://rvm.io/
[aws-s3]: https://aws.amazon.com/s3/
[minio]: https://min.io
[postgres]: https://www.postgresql.org/
[mailcatcher]: https://mailcatcher.me/
[drone]: https://drone.io
[heroku]: https://herokuapp.com
