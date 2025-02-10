package haskell.prelude;

import java.util.ArrayList;

public class List {
    public ListNode head;

    public List(ListNode head) {
        this.head = head;
    }

    public List(int... values) {
        ListNode currentNode = null;
        for (int i = values.length - 1; i >= 0; i--) {
            currentNode = new ListNode(values[i], currentNode);
        }
        this.head = currentNode;
    }

    public List(int val) {
        this.head = new ListNode(val);
    }

    public List() {
        this.head = null;
    }

    public static List create() {
        return new List();
    }

    public static int length(List lst) {
        ListNode curNode = lst.head;
        int length = 0;

        while (curNode != null) {
            curNode = curNode.next;
            length++;
        } 

        return length;
    }

    public static List prepend(List lst, int value) {
        ListNode newHead = new ListNode(value, lst.head);
        return new List(newHead);
    }

    public static int head(List lst) {
        return lst.head.value;
    }

    public static List tail(List lst) {
        return new List(lst.head.next);
    }

    public String toString() {
        ArrayList<String> values = new ArrayList<>();

        ListNode currentNode = this.head;
        while (currentNode != null) {
            values.add(Integer.toString(currentNode.value));
            currentNode = currentNode.next;
        }

        return "[" + String.join(", ", values) + "]";
    }
}
