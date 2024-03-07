cat color_test.sh
#!/bin/bash
#
# generates an 8 bit color table (256 colors) for reference,
# using the ANSI CSI+SGR \e[48;5;${val}m for background and
# \e[38;5;${val}m for text (see "ANSI Code" on Wikipedia)
#
echo -en "\n   +  "
for i in {0..35}; do
        printf "%2b " $i
done
printf "\n\n %3b  " 0
for i in {0..15}; do
echo -en "\e[48;5;${i}m  \e[m "
done

for i in {0..6}; do
        i=$((i*36 +16))
        printf "\n\n %3b  " $i
        for j in {0..35}; do
                val=$((i+j))
                echo -en "\e[48;5;${val}m  \e[m "
        done
done
echo -e "\n"	