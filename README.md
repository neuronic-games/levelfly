# Levelfly

![Levelfly logo](public/images/levelfly_tag.png?raw=true)

[![Build Status](https://drone.neuronicgames.com/api/badges/neuronic-games/levelfly/status.svg?ref=refs/heads/staging)](https://drone.neuronicgames.com/neuronic-games/levelfly)

Levelfly is an open-source, achievement-based Learning Management System (LMS) and social network, developed by [Neuronic Games][neuronic] for [Borough of Manhattan Community College][bmcc] and [City University of New York][cuny] with funding from the [National Science Foundation][nsf] and the [U.S. Department of Education][us-doe].

A demonstration instance of Levelfly is available at <https://demo.levelflylearning.com>

## Working on Levelfly

Check out the Levelfly code:

```shell
git clone https://github.com/neuronic-games/levelfly.git && cd levelfly
```

Then, decide how you'd like to run Levelfly and its dependencies.

### Docker

If you have [Docker][docker] installed, you can use it to run a local development version of Levelfly, including all the necessary software:

```shell
docker-compose up
```

This will probably take a while. You can tell if it's worked if you see messages like this:

```
app-1   | => Rails 7.2.2.2 application starting in development http://0.0.0.0:3000
app-1   | => Run `bin/rails server --help` for more startup options
```

If you see something else, check the "Troubleshooting" section below.

Otherwise, if all is well, run this to set up the database and load initial data:

```shell
docker-compose exec app db:reset
```

Then, you should be able to open <http://localhost:3000> in a web browser, and log in with the default user:

* Username: `admin@neuronicgames.com`
* Password: `changeme`

You can access Mailcatcher to see sent emails at <http://localhost:1080>

#### Troubleshooting

If you get something like "command not found" when running `docker-compose`, you can try `docker compose up` (newer syntax).

You might need `sudo` depending on the permissions settings on your computer.

If you run into a different problem, please open a [Github issue][github-issue]

### "Bare metal" (non-Docker) install

These instructions have been tested on Linux & OSX. If you can add set-up instructions for any other platform, please [edit this README][editreadme] and share your wisdom!

1. Install [Postgres][postgres], and Ruby 3.3.9 ([rbenv][rbenv] is recommended)
2. Create a Postgres database:

   ```shell
   createdb -U postgres levelfly
   ```

3. Copy `.env.example` to `.env` and edit as appropriate
4. Initialise the database:

    ```shell
    bundle exec rake db:create
    bundle exec rake db:migrate
    bundle exec rake db:seed
    ```

5. Set up S3 storage – either sign up for [AWS][aws-s3] or set up [minio][minio].
6. Install [MailCatcher][mailcatcher] to display outgoing mail in a browser instead of sending it:

    ```shell
    gem install mailcatcher
    mailcatcher
    ```

8. Run the server and job workers:

    ```shell
    bundle exec rake jobs:work &
    rails s
    ```

## Automated testing

See [`TESTING.md`](./TESTING.md)

## Deploying Levelfly

The easiest way to deploy Levelfly is using the [`neuronicgames/levelfly` Docker image][docker-image].

An example production `compose.yml` for Docker Swarm is available from [Co-op Cloud][coop-cloud-levelfly].

Otherwise, you could make a production `docker-compose.yml` based on the existing development `docker-compose.yml` in this repo.

### Updating

The `neuronicgames/levelfly` Docker image is automatically updated using [Drone][drone] push to the `main` or `staging` branches of this repository. You can see the status of deployments here:

<https://drone.neuronicgames.com/neuronic-games/levelfly>

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
[rbenv]: https://github.com/rbenv/rbenv
[aws-s3]: https://aws.amazon.com/s3/
[minio]: https://min.io
[postgres]: https://www.postgresql.org/
[mailcatcher]: https://mailcatcher.me/
[drone]: https://drone.io
[heroku]: https://herokuapp.com
[docker]: https://www.docker.com/
[github-issue]: https://github.com/neuronic-games/levelfly/issues
[docker-image]: https://hub.docker.com/r/neuronicgames/levelfly
[coop-cloud-levelfly]: https://git.coopcloud.tech/coop-cloud/levelfly

## Screens

![Levelfly course](public/images/course_2.png?raw=true)
![Levelfly grades](public/images/grade_book_1.png?raw=true)
![Levelfly messages](public/images/message_1.png?raw=true)
![Levelfly profile](public/images/profile_1_draft.png?raw=true)
