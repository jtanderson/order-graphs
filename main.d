/*
* File: main.d
*
* Experimental file to attempt brute-forcing the construction of partial order
* graphs Gamma(k,n) and then to investigate their structural properties.
*
* @author: Joe Anderson <jtanderson@salisbury.edu>
* @date:   3 July 2019
*/

import std.stdio : writeln, writefln;


int main(){
  int a = 10;

  int[string] map;
  map["lala"] = 54;

  writefln("Biggest int is %d", a.max);
  writefln("Name of a is %s", a.stringof);

  foreach(el; map.byKey){
    writeln(el);
  }

  return 0;
}
