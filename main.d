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

/*
   A tuple of integers capturing the structure of a young diagram
 */
alias ydiagram = int[];

struct Graph {
  struct node {
    ydiagram yd;
    node* down = null;
    node* up = null;
  }

  int n, k;

  // record which nodes are at which level in the graph
  node*[][] nodes;

  node* root;

  this(int k, int n){
    this.n = n;
    this.k = k;

    root = new node;
    node* cursor = root;

    nodes.length = this.n * (this.n - this.k);

    // append the root to layer 0
    nodes[0] ~= root;
    int level = 1;

    // connect-four logic: can choose any row that is < the one above it
    // note: this corresponds to incrementing a coordinate in the corresponding
    // tuple representation of the diagram
    while( !isFull(cursor) ){
      auto tmp = new node;
      tmp.yd = cursor.yd.dup;
    }

    // make sure the last node in the last level (there should only be one) is full
    assert(nodes[$].length == 1);
    assert(isFull(nodes[$][$]));
  }

  // all rows are used
  bool isRowFull(node* n){
    return n.yd[$] > 0;
  }

  // all cols are used
  bool isColFull(node* n){
    return n.yd[0] > 0; 
  }

  // all spaces are full
  bool isFull(node* n){
    return n.yd[$] == this.n - this.k;
  }
}



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
