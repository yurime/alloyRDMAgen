


/**
 * Created by yuri on 20/8/15.
 */
public class Node {
    int nodeNumber;

    public Node(int n) {
        this.nodeNumber = n;
    }

    @Override
    public String toString() {
        return nodeNumber + "";
    }

    @Override
    public boolean equals(Object other) {
        if (other instanceof Node)
            return ((Node)other).nodeNumber == nodeNumber;
        return false;
    }

    @Override
    public int hashCode() {
        return nodeNumber;
    }
}
