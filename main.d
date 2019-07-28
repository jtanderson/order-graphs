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
import std.conv : parse, to;
import std.format : format;
import std.file : read, fout = write, exists, readText;
import std.string : split;
import std.algorithm : map;
import std.array : join;

/*
   A tuple of integers capturing the structure of a young diagram
 */
alias ydiagram = int[];

struct Graph {
  struct node {
    ydiagram yd;
    node*[] downs;
    node* up;
    ulong[2] coords;

    string toStrTuple(){
      return yd.map!(x => to!string(x)).join(",");
    }

    string getTexName(){
      return format("node-%s-%s", coords[0], coords[1]);
    }

    ydiagram getReduced(){
      ydiagram tmp = yd[1 .. $].dup;
      tmp[] -= 1;
      tmp ~= [0];
      writefln("Reduced ydiagram of (%s) is (%s)", 
          yd.map!(x => to!string(x)).join(","),
          tmp.map!(x => to!string(x)).join(","));
      return tmp;
    }

    ydiagram getTwoReduced(){
      ydiagram tmp = yd[2 .. $].dup;
      tmp[] -= 2;
      tmp ~= [0,0];
      writefln("Reduced ydiagram of (%s) is (%s)", 
          yd.map!(x => to!string(x)).join(","),
          tmp.map!(x => to!string(x)).join(","));
      return tmp;
    }

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
    foreach( level; 0 .. (k*(n-k))+1 ){
      foreach( level_node; 0 .. nodes[level].length ){
        // cursor is the ydiagram we are mutating
        cursor = nodes[level][level_node];

        if ( level < (k*(n-k))+1 ){
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
                tmp.coords = [level+1, nodes[level+1].length];
                nodes[level+1] ~= tmp;
                cursor.downs ~= tmp;
              }
            }
          }
        }

        // TODO: pull this out and parameterize so we can remove the if
        //       above
        // TODO: this is ridiculous... stop using pointers
        //       and start using the yd to identify nodes
        if( isTwoRowFull(cursor) && isTwoColFull(cursor) ){
          ydiagram red = cursor.getTwoReduced();
          foreach( j; 0 .. level ){
            foreach( l; 0 .. nodes[j].length ){
              if( nodes[j][l].yd == red ){
                cursor.up = nodes[j][l];
                //break; // sigh, only breaks one level
              }
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
    string fname = format!"graphs/graph-%s-%s.tex"(k, n);
    scope(exit) assert(exists(fname));

    string nodeFmt = r"\node [%s %s of=%s] (%s) {\ydiagram{%s}};";
    string edgeFmt = r"\draw (%s) -- (%s);";

    string nodesTex = "";
    string edgesTex = "";
    string prevLeft = "node-0-0";
    bool   topHalf  = true;
    string side     = "";
    string name, prevName;

    // For every level of the graph...
    foreach( level; 1 .. nodes.length ){
      // pre-load the first one

      side = topHalf ? "left" : "right";

      name = nodes[level][0].getTexName();
      prevName = name;

      nodesTex ~= format(nodeFmt, "below", side, prevLeft, name, nodes[level][0].toStrTuple());
      nodesTex ~= "\n";
      prevLeft = name;

      // do the down arrows
      foreach( edge; nodes[level][0].downs ){
        edgesTex ~= format(edgeFmt, name, edge.getTexName());
        edgesTex ~= "\n";
      }

      // add the up arrow
      if( nodes[level][0].up ){
        string upEdge = format(edgeFmt, name, nodes[level][0].up.getTexName());
        edgesTex ~= upEdge;
        edgesTex ~= "\n";
      }

      // For each node in the level...
      foreach( n; 1 .. nodes[level].length ){
        name = nodes[level][n].getTexName();
        nodesTex ~= format(nodeFmt, "", "right", prevName, name, nodes[level][n].toStrTuple());
        nodesTex ~= "\n";
        prevName = name;

        // do the down arrows
        foreach( edge; nodes[level][n].downs ){
          edgesTex ~= format(edgeFmt, name, edge.getTexName());
          edgesTex ~= "\n";
        }

        // add the up arrow
        if( nodes[level][n].up ){
          string upEdge = format(edgeFmt, name, nodes[level][n].up.getTexName());
          edgesTex ~= upEdge;
          edgesTex ~= "\n";
        }
      }

      if ( level >= nodes.length/2 ){
        topHalf = false;
      }
    }

    writeln(nodesTex);
    writeln(edgesTex);

    string tmplt = readText("template.tex");
    auto templts = tmplt.split("@@@");

    fout(fname, templts[0] ~ nodesTex ~ edgesTex ~ templts[1]);
  }


  // all spaces are full
  bool isFull(node* n){
    return n.yd[$-1] == this.n - this.k;
  }

  // all rows are used
  bool isRowFull(node* n){
    return n.yd[$-1] > 0;
  }

  // all cols are used
  bool isColFull(node* n){
    return n.yd[0] == this.n-this.k; 
  }

  // all rows are used
  bool isTwoRowFull(node* n){
    return n.yd[$-1] > 0 && n.yd[$-2] > 0;
  }

  // all cols are used
  bool isTwoColFull(node* n){
    return n.yd[0] == this.n-this.k && n.yd[1] == this.n - this.k; 
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

  g.saveToTex();

  return 0;
}
