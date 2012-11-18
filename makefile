PROJECT_NAME = grains
COMPILE_COMMAND = dmd -c 
LINK_COMMAND = dmd -L-ldl
RM_COMMAND = rm
COMPILE_OPTIONS = -g -gs
OBJ_SUFFIX = .o
LIB_SUFFIX = .a
LIB_PREFIX = -L/usr/local/lib/lib
EXE_SUFFIX = 
OBJS = util$(OBJ_SUFFIX) app$(OBJ_SUFFIX) devices$(OBJ_SUFFIX) grains$(OBJ_SUFFIX)


$(PROJECT_NAME): $(OBJS)
	@echo -e "\e[1;36m[Link]\e[0m"
	@$(LINK_COMMAND) $(LIB_PREFIX)DerelictSDL2$(LIB_SUFFIX) $(LIB_PREFIX)DerelictUtil$(LIB_SUFFIX) $(OBJS) -of$(PROJECT_NAME)$(EXE_SUFFIX)

clean:
	$(RM_COMMAND) $(OBJS) $(PROJECT_NAME)$(EXE_SUFFIX)

util$(OBJ_SUFFIX): util.d
	@echo -e "\e[1;32m[util.d]\e[0m"
	@$(COMPILE_COMMAND) $(COMPILE_OPTIONS) util.d

app$(OBJ_SUFFIX): app.d
	@echo -e "\e[1;32m[app.d]\e[0m"
	@$(COMPILE_COMMAND) $(COMPILE_OPTIONS) app.d

devices$(OBJ_SUFFIX): devices.d
	@echo -e "\e[1;32m[devices.d]\e[0m"
	@$(COMPILE_COMMAND) $(COMPILE_OPTIONS) devices.d

grains$(OBJ_SUFFIX): grains.d
	@echo -e "\e[1;32m[grains.d]\e[0m"
	@$(COMPILE_COMMAND) $(COMPILE_OPTIONS) grains.d

