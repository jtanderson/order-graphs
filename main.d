/*
 * File: main.d
 *
 * Experimental file to attempt brute-forcing the construction of partial order
 * graphs Gamma(k,n) and then to investigate their structural properties.
 *
 * @author: Joe Anderson <jtanderson@salisbury.edu>
 * @date:   3 July 2019
 */

import std.stdio : write, writeln, writefln;
import std.conv : parse;
import std.format : format;
import std.file : read, write, exists, readText;
import std.string : split;

/*
   A tuple of integers capturing the structure of a young diagram
 */
alias ydiagram = int[];

struct Graph {
  struct node {
    ydiagram yd;
    node*[] downs;
    node* up;
  }

  int n, k;
  int cols;

  // record which nodes are at which level in the graph
  node*[][] nodes;

  int[int[][2]] A;

  node* root;

  void fillMatrix(int k, int n){
    this.n = n;
    this.k = k;
    this.cols = n - k;
  }

  this(int k, int n){
    this.n = n;
    this.k = k;

    root = new node;
    root.yd.length = k;

    // one extra level for the emptyset
    nodes.length = this.k * (this.n - this.k) + 1;

    // append the root to layer 0
    nodes[0] ~= root;
    //int level = 0;
    //int level_node = 0;

    node* cursor;

    // connect-four logic: can choose any row that is < the one above it
    // note: this corresponds to incrementing a coordinate in the corresponding
    // tuple representation of the diagram
    foreach( level; 0 .. (k*(n-k)) ){
      foreach( level_node; 0 .. nodes[level].length ){
        // cursor is the ydiagram we are mutating
        cursor = nodes[level][level_node];

        // loop over the rows of cursor, at most k of them
        foreach( row; 0 .. k ){
          // tmp is the next possible ydiagram, mutated from cursor
          // start tmp as a new node to avoid dup edges
          auto tmp = new node;
          tmp.yd = cursor.yd.dup;

          // check to see if we can add a block to row i
          if( 
              (row == 0 && tmp.yd[row] < n - k) ||    // the top row
              (row > 0 && tmp.yd[row] < tmp.yd[row-1])  // an inside row
            ){

            tmp.yd[row]++; // add a block to that row
            auto found = containsSame(level+1, tmp);
            if( found ){
              cursor.downs ~= found;
            } else {
              nodes[level+1] ~= tmp;
              cursor.downs ~= tmp;
            }
          }
        }
      }
      write("Finised level: ", level);
      writeln(" -- Level size: ", nodes[level].length);
    }
    assert(nodes[$-1].length == 1);
    assert(isFull(nodes[$-1][$-1]));
  }

  void print(){
    foreach(i; 0 .. nodes.length){
      foreach(j; 0 .. nodes[i].length ){
        write("(");
        foreach(kk; 0 .. nodes[i][j].yd.length ){
          write(nodes[i][j].yd[kk], ", ");
        }
        write(") ");
      }
      writeln("");
    }
  }

  node* containsSame(int level, node* test){
    foreach(nodeptr; nodes[level]){
      if( nodeptr.yd == test.yd ){
        return nodeptr;
      }
    }
    return null;
  }

  void saveToTex(){
    string fname = format!"graph-%s-%s.tex"(k, n);
    scope(exit){
      assert(exists(fname));
    }

    string nodes_tex = "";
    string edges_tex = "";
    foreach( level; 0 .. nodes.length ){
      foreach( n; 0 .. nodes[level].length ){
        nodes_tex ~= "\n";
      }
    }

    string tmplt = readText(fname);
    auto templts = tmplt.split("@@@");
  }

  // all rows are used
  bool isRowFull(node* n){
    return n.yd[$-1] > 0;
  }

  // all cols are used
  bool isColFull(node* n){
    return n.yd[0] > 0; 
  }

  // all spaces are full
  bool isFull(node* n){
    return n.yd[$-1] == this.n - this.k;
  }
}

int main(string[] args){
  //Graph g = Graph(args[1],args[2]);
  int k,n;

  if( args.length < 3 ){
    writeln("Not enough arguments! Need k and n.");
    return 1;
  }

  k = parse!int(args[1]);
  n = parse!int(args[2]);

  if( k >= n ){
    writeln("Invalid input: k < n required");
    return 2;
  }
  
  Graph g = Graph(k,n);

  g.print();

  return 0;
}
