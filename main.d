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

  // record which nodes are at which level in the graph
  node*[][] nodes;

  node* root;

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
        foreach ( row; 0 .. k ){
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
    }
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
  Graph g = Graph(2,5);

  g.print();

  return 0;
}
