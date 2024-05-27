int main()
{
    long n = 6;
    long sum = 0;

    for(long i = 2; i < n; ++i) {
        sum += i;
    }

    asm("ecall");
}
