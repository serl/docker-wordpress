# Docker WordPress skeletonist

Welcome to the very wrong way to run WordPress on Docker!


## What is this for?

Let's say you need to build a WordPress site on a domain that already hosts a website, but you don't want any downtime.

WordPress, upon installation, hard-code its root URI in various places on the database. While you can simply run some queries to fix this if you change the URI, I wanted to build a tool that lets me circumvent the issue, by configuring everything directly with the right domain name.

You could also use this technique to take a copy of a WordPress-based website and reliably run it locally.


## How

When you run `./build_and_run.sh <domain_name> [alternative_domain_name]...`:

* (A container with all the dependencies is built. This could take some time the first time.)
* The domain names are put in your hosts file, mapped to `127.0.0.1`.
* A container consisting of Apache, PHP and MySQL is built and started.
* WordPress is downloaded. You could then head your browser to `domain_name` and configure your website.
* The terminal that you get points to the WordPress root. [WP-CLI](http://wp-cli.org/) is installed for your convenience.
* When you're done, hit CTRL+D. The container will be stopped, and you'll have all you need to upload to your hosting in the `output` dir (just remember to edit the `wp-config.php` to match production database). Note that `output/dump.sql` is updated in this moment.

If you need to continue your work, just run `./build_and_run.sh`, and everything will be running local again. (Note: in this case you don't need to specify the domain name)

When you are done and you want to wipe everything out, run `./build_and_run.sh clean`.

If you want to run locally a pre-existing website, put the WordPress copy in `output/www` folder (the existence of a `index.php` file will inhibit the download of a fresh WordPress), and the dump of your database in `output/dump.sql`; the database credentials for your `wp-config.php` are: username `root`, password `easy`, database name `wordpress`. Then launch the command specifying `domain_name`.


## Prerequisites

* Ehm... Docker.
* Nothing else listening on port 80.
