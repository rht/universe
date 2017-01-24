upload:
	rm -rf dist
	python setup.py sdist
	twine upload dist/*

test:
	find . -name '*.pyc' -delete
	docker build -f test.dockerfile -t quay.io/openai/universe:test .
	docker run -v /usr/bin/docker:/usr/bin/docker -v /root/.docker:/root/.docker -v /var/run/docker.sock:/var/run/docker.sock --net=host quay.io/openai/universe:test

build:
	find . -name '*.pyc' -delete
	docker build -t quay.io/openai/universe .
	docker build -f test.dockerfile -t quay.io/openai/universe:test .

deps:
	set -e ;\
	UNAME_S=$$(uname -s) ;\
	if [ "$$UNAME_S" = "Linux" ]; then \
		DIST=$$(lsb_release -si) ;\
	    if [ "$$DIST" = "Ubuntu" ]; then \
			echo 'Preparing Ubuntu dependencies' ;\
			VER=$$(lsb_release -sr) ;\
			if [ "$$VER" = "16.04" ]; then \
				apt-get install golang libjpeg-turbo8-dev make ;\
				echo 'Dependencies installed in 16.04' ;\
			elif [ "$$VER" = "14.04" ]; then \
				add-apt-repository ppa:ubuntu-lxc/lxd-stable -y ;\
				apt-get update ;\
				apt-get install golang libjpeg-turbo8-dev make ;\
				echo 'Dependencies installed in 14.04' ;\
			else \
				echo 'Your Ubuntu version is not supported. Before running the next install step,' ;\
				echo 'make sure to have golang>=1.5 and libjpeg-turbo8-dev installed.' ;\
			fi \
		else \
			echo 'Your Linux distribution is not supported. Before running the next install step,' ;\
			echo 'make sure to have golang>=1.5 and libjpeg-turbo8-dev installed.' ;\
			echo 'In case you have succesfully installed universe, let us know.' ;\
		fi \
	elif [ "$$UNAME_S" = "Darwin" ]; then \
		echo 'Preparing Darwin dependencies' ;\
		if type xcode-select >&- && xpath=$( xcode-select --print-path ) && [ -d "$xpath" ] && [ -x "$xpath" ]; then \
			: ;\
		else \
			echo 'You might need to first install Command Line Tools by running:' ;\
			echo 'xcode-select --install' ;\
		    echo 'then re-run `make deps`' ;\
		fi ;\
		if ! type brew >/dev/null 2>&1; then \
			if ! type port >/dev/null 2>&1; then \
				echo 'Neither `brew` nor `port` is installed' ;\
		        echo 'Please visit http://brew.sh/ or https://www.macports.org/' ;\
		    else \
				port install go libjpeg-turbo ;\
		    fi \
		else \
			brew install golang libjpeg-turbo ;\
		fi \
	else \
		echo 'Your OS is not supported. Before running the next install step,' ;\
		echo 'make sure to have golang>=1.5 and libjpeg-turbo8-dev installed.' ;\
	fi

push:
	find . -name '*.pyc' -delete
	docker build -t quay.io/openai/universe .
	docker build -f test.dockerfile -t quay.io/openai/universe:test .

	docker push quay.io/openai/universe
	docker push quay.io/openai/universe:test

test-push:
	docker build -f test.dockerfile -t quay.io/openai/universe:test .
	docker push quay.io/openai/universe:test
