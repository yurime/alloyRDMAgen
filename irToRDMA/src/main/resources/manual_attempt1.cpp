#include <iostream>
using std::cout;
using std::cerr;
using std::endl;
using std::ostream;

#include <thread>
//std::thread


#include "../resources.h"
using rdma::Resources;

#include "../connection.h"
using rdma::Connection;

#include "../connection_manager.h"
using rdma::ConnectionManager;

//for include ..random
#include <stdio.h>      /* printf, scanf, puts, NULL */
#include <stdlib.h>     /* srand, rand */
#include <time.h>       /* time */
//end of for include ..random

#define SERVER_ID 0
#define PORT 19875
/******************************************************************************************/
/******************************************************************************************/
/**                                                                                      **/
/**                              hash table use case                                     **/
/**                                                                                      **/
/******************************************************************************************/
/******************************************************************************************/

#define LOCAL_SHARED(varName,con) \
        rdma::LocalConData<uint64_t>  varName##_res("varName");\
        auto& varName = varName##_res.get(); \
        con.addLocalResource(varName##_res);\
        varName

#define SILENT_SYNC(msg) {\
    if (!con.sync())  { \
        cerr << "failed to sync at the " << msg << endl;  \
        return 1;\
        }\
    }

int thr1(){//server(number_of_clients=1){
    //--------------------------------------------------------
    //-------------- Set up ----------------------------------
    int ret = 0;

    ConnectionManager con(SERVER_ID, PORT);

    LOCAL_SHARED(Y1, con) = 2;
    LOCAL_SHARED(Y2, con) = 1;

    /* initialize random seed: */
    srand (time(NULL));
    
    /* connect the QPs */
    con.add_connection(1, "");
    if (con.connectQP())
    {
        cerr << "failed to connect QPs" << endl;
        return 1;
    }
    cout << "connected to queue" << endl;  

    rdma::RemConData X_res = con.getRemoteEntry("X");

    SILENT_SYNC("program start");

    cout << "starting test" << endl;  
    // --------------------------------------------------------
    // -------------- Do something -----------------------------
    try{
        if (con.at(1).postWRITE(Y1_res, X_res))   {
                cerr << PORT << " failed to post FetchAndAdd request" << endl;
                return 1;
        }
        if (con.at(1).postWRITE(Y2_res, X_res))   {
                cerr << PORT << " failed to post FetchAndAdd request" << endl;
                return 1;
        }
    }catch(std::exception &e){
        cerr << "Server failed because " << e.what() << endl;
        ret =1;
    }  
    sleep(10);

    //--------------------------------------------------------
    //-------------- End operations ---------------------------
 

    SILENT_SYNC("end of operations");

    cout << "Y1="<< Y1 << "; Y2="<< Y2 << endl;
    cout << "ended test" << endl;  
    
    return ret;
}



int thr0(string server_name, u_int32_t tcp_port, int cliend_id){
    //--------------------------------------------------------
    //-------------- Set up ----------------------------------
 
    rdma::Connection con(server_name, SERVER_ID, cliend_id, tcp_port);
        
    LOCAL_SHARED(X, con) = 0;
    uint64_t c1,c2;

    if (con.connectQP())
    {
        cerr << tcp_port << " failed to connect QPs" << endl;
        return 1;
    }
    
    SILENT_SYNC("program start");
    
    //--------------------------------------------------------
    //-------------- Do something -----------------------------
    c1 = X;
    c2 = X;
    //--------------------------------------------------------
    //-------------- End operations ---------------------------
    
    SILENT_SYNC("end of operations");

    if( ! (c1==2 && c2==1) ){
        cout << "test was successfull" << endl;
    }else{
        cout << "test Failed" << endl;
    }
    cout << "X="<< X << "; c1="<< c1 << "; c2="<< c2 <<endl;
    cout << "ended test" << endl;  
    return 0;

}



int main (int argc, char *argv[])
{
    string server_name;
    int my_id=SERVER_ID;
   // int number_of_clients=1;
    // INITIALIZATION phaze

    if(argc < 1){
        cout << "Expected  \"s\" if server or server_ip, folowed by cliend id got no parameters " 
             << endl;
        return 1;
    }
    
    if (*argv[1] != 's'){
            if(argc < 2){
                cout << "Expected  \"s\" if server or server_ip, folowed by cliend id got: " 
                 << endl
                 << argv[1] <<
                 endl;
                 cout << "Did not recieve client id!" << endl;
                 return 1;
            }

            cout << argv[2] 
                << endl;
            server_name = string(argv[1]); //if not server: 10.10.16.174
            my_id = std::stoi(argv[2]);
    }else{
        //  if(argc < 2){
        //     cout << "Expected  \"s\" if server, followed by "
        //         <<"number_of_clients connecting, but didn't recieve a second parameter" << endl;
        //     return 1;
        // }
        // number_of_clients = std::stoi(argv[2]);
    }

    rdma::Resources::initialize();

    int rc = 0;
    if (server_name.empty()){
        rc = thr1();
        std::cout << "server";
    } else{
        rc = thr0(server_name, PORT, my_id);
        std::cout << "client";
    }

    // Destruction/cleanup phaze

    if(rc){
        cout << " had an error" << endl;
        return 1;
    }
  
    cout << " has completed" << endl;

    return 0;
}
