VERSION=$(shell git describe --tags $(git rev-list --tags --max-count=1))

lint: 
	ukor lint main
	
test: 
	ukor test main roku2
	
zip: 
	rm -rf out build .ukor && mkdir -p out && mkdir -p build
	ukor make main
	cp build/main.zip out/qaApp_$(VERSION).zip
