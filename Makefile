CXX=dmd
CXXFLAGS=

all: main

main: main.o
	$(CXX) $(CXXFLAGS) main.o

main.o: main.d
	$(CXX) -c $(CXXFLAGS) main.d
