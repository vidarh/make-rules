
bundle:
	bundle install --path=vendor/bundle

shotgun:
	bundle exec shotgun -o 0.0.0.0 -s thin -p 8080

pry:
	bundle exec pry -I. -r app
