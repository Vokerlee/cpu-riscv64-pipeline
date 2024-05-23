int main()
{
    long n = 6;

    long a = 0, b = 1;
    for(long i = 2; i < n; ++i) {
        long tmp = a;
        a = b;
        b = tmp ^ a;
    }

    asm("ecall");
}
