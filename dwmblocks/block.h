typedef struct {
        char *const pathu;
        char *const pathc;
        const int interval;
        const int signal;
        char curtext[CMDOUTLENGTH + 1 + DELIMITERLENGTH];
        size_t length;
        int failed;
} Block;
