gitlab2jenkins
==============

Gitlab2jenkins is a simple web application, which makes a proxy between Gitlab and Jenkins CI.

...

It is written in Ruby (Sinatra) and is capable of running on OpenShift cloud.

Requirements
------------

OpenShift with Ruby 1.9, MySQL 5.1, and Foreman

Quick start
-----------

```
rhc app create gitlab2jenkins ruby-1.9 mysql-5.1 http://cartreflect-claytondev.rhcloud.com/reflect?github=ncdc/openshift-foreman-cartridge --from-code https://github.com/fcelda/gitlab2jenkins.git
```

Jenkins job: remember name, build with parameters (needs secret token), parameters commit and branch

```
rhc ssh gitlab2jenkins 'cd app-root/repo && bundle exec ./add_project.rb "Awesome Project" awesome_project secret-token'
Project: Awesome Project
Jenkins: awesome_project (token secret-token)
Token:   gitlab2jenkins-generated-token
```

Generated token is used for Gitlab authentication to gitlab2jenkins.

Gitlab CI url should be set to `http://gitlab2jenkins-<namespace>.openshift.com/projects/<project-id>`.

Manual trigger for new builds in Jenkins (should not be needed):

```
rhc ssh gitlab2jenkins 'cd app-root/repo && bundle exec ./update_builds.rb once'
```
