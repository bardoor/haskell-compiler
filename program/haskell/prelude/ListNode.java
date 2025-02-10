package haskell.prelude;

public class ListNode {
    public final int value;
    public final ListNode next;

    public ListNode(int value, ListNode next) {
        this.value = value;
        this.next = next;
    }

    public ListNode(int value) {
        this.value = value;
        this.next = null;
    }
}

