COMPILE_OPTIONS = -g -gs
OBJS = app.o devices.o grains.o util.o
RED_COLOR=`echo -e '\e[0;31m'`
END_COLOR=`echo -e '\e[0m'`


grains: $(OBJS)
	@echo -e "\e[0;36m[Link]\e[0m"
	@dmd -L/usr/local/lib/libDerelictSDL2.a -L/usr/local/lib/libDerelictUtil.a -L-ldl $(OBJS) -ofgrains

app.o: app.d
	@echo -e "\e[0;32m[app.d]\e[0m"
	@dmd -c $(COMPILE_OPTIONS) app.d

devices.o: devices.d
	@echo -e "\e[0;32m[devices.d]\e[0m"
	@dmd -c $(COMPILE_OPTIONS) devices.d

grains.o: grains.d
	@echo -e "\e[0;32m[grains.d]\e[0m"
	@dmd -c $(COMPILE_OPTIONS) grains.d

util.o: util.d
	@echo -e "\e[0;32m[util.d]\e[0m"
	@dmd -c $(COMPILE_OPTIONS) util.d

clean:
	rm $(OBJS)
