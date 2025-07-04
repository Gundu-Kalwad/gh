#include <stdio.h>

// Function to perform insertion sort on an array
void insertionSort(int arr[], int n) {
    int i, key, j;
    // Iterate through the array starting from the second element
    // (the first element is considered sorted)
    for (i = 1; i < n; i++) {
        key = arr[i]; // Store the current element as 'key'
        j = i - 1;    // Initialize 'j' to the index of the element before 'key'

        // Move elements of arr[0..i-1], that are greater than key,
        // to one position ahead of their current position
        while (j >= 0 && arr[j] > key) {
            arr[j + 1] = arr[j]; // Shift element to the right
            j = j - 1;           // Move to the previous element
        }
        arr[j + 1] = key; // Place the 'key' in its correct sorted position
    }
}

// Function to print an array
void printArray(int arr[], int n) {
    int i;
    for (i = 0; i < n; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");
}

// Main function to test the insertion sort
int main() {
    int arr[] = {12, 11, 13, 5, 6}; // Example array
    int n = sizeof(arr) / sizeof(arr[0]); // Calculate the size of the array

    printf("Original array: \n");
    printArray(arr, n);

    insertionSort(arr, n); // Call the insertion sort function

    printf("Sorted array: \n");
    printArray(arr, n);

    return 0; // Indicate successful execution
}

