#include <iostream>
using std::cout;
using std::cerr;
using std::endl;
using std::ostream;

#include <thread>
//std::thread


// //for include ..random
// #include <stdio.h>      /* printf, scanf, puts, NULL */
// #include <stdlib.h>     /* srand, rand */
// #include <time.h>       /* time */
// //end of for include ..random and sleep(10)

#include "rdma_code/resources.h"
using rdma::Resources;

#include "rdma_code/connection.h"
using rdma::Connection;

#include "rdma_code/connection_manager.h"
using rdma::ConnectionManager;

#define SERVER_ID 0
#define PORT 19875
#define FILE_NAME "manual_attempt1.cpp"//$0;
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

#define REMOTE_SHARED(varName,con) \
    rdma::RemConData varName##_res = con.getRemoteEntry(#varName);

#define SILENT_SYNC(msg) {\
      if (!con.sync())  { \
        cerr << "failed to sync at the " << msg << endl;  \
        return 1;\
      }\
    }

#define POST_PUT(con,my_name,fromVarName,targVarName){\
        if (con.postWRITE(fromVarName##_res, targVarName##_res))   {\
                cerr << my_name << " failed to post postWRITE request" << endl;\
                return 1;\
       }\
   }

#define POST_GET(con,my_name,fromVarName,targVarName){\
        if (con.postREAD(targVarName##_res, fromVarName##_res))   {\
                cerr << my_name << " failed to post postREAD request" << endl;\
                return 1;\
       }\
   }

#define POLL_CQ(con,my_name){\
    if (con.pollCompletion ())  {\
        cerr << my_name << " poll completion failed 2" << endl;\
        return 1;\
        }\
    }

int thr0(){//server(number_of_clients=1){
    //--------------------------------------------------------
    //-------------- Set up ----------------------------------
    int ret = 0;
     //$05 // incorporate local declaration;
    ConnectionManager con(SERVER_ID, PORT);
    //$03     // incorporate test init;
    LOCAL_SHARED(Y1, con) = 2;
    LOCAL_SHARED(Y2, con) = 1;

    LOCAL_SHARED(tr1_c1, con) = 1;
    LOCAL_SHARED(tr1_c2, con) = 1;

    
    /* connect the QPs */
    con.add_connection(1, "");
    if (con.connectQP())
    {
        cerr << "failed to connect QPs" << endl;
        return 1;
    }
    cout << "connected to queue" << endl;  
    //$10 //incorporate remotely accessed varaibles;
    REMOTE_SHARED(X, con.at(1));

    //$13 //incorporate test body;
    // --------------------------------------------------------
    // -------------- Do something -----------------------------
    SILENT_SYNC("program start");

    cout << "starting test" << endl;  

    try{
        POST_PUT(con.at(1),PORT,Y1, X);
        POST_PUT(con.at(1),PORT,Y2, X);
        POLL_CQ(con.at(1),PORT);
        POLL_CQ(con.at(1),PORT);
    }catch(std::exception &e){
        cerr << "Server failed because " << e.what() << endl;
        ret =1;
    }  
    sleep(10);

    //--------------------------------------------------------
    //-------------- End operations ---------------------------
 
    SILENT_SYNC("end of operations");


    SILENT_SYNC("end of collecting results");
  
    //$14 //incorporateTestWitnesses(os);  
    if( ! (tr1_c1==2 && tr1_c2==1) ){
        cout << FILE_NAME << ":Success" << endl;
    }else{
        cout << FILE_NAME  << ":Failed reaching the forbidden output:" << endl;
        cout << "(tr1:c1==2 && tr1:c2==1)" << endl;
    }
    cout << "Y1="<< Y1 << "; Y2="<< Y2 << endl;
    cout << "ended test" << endl;  
    SILENT_SYNC("end of validating results");
    return ret;
}



int thr0(string server_name, u_int32_t tcp_port, int cliend_id){
    //--------------------------------------------------------
    //-------------- Set up ----------------------------------
 
     //$5 // incorporate local declaration;

    rdma::Connection con(server_name, SERVER_ID, cliend_id, tcp_port);
    //$3   incorporateSharedVarDecls(os);
    LOCAL_SHARED(X, con) = 0;
    LOCAL_SHARED(Scrap, con) = 1;
    uint64_t c1,c2;

    if (con.connectQP())
    {
        cerr << tcp_port << " failed to connect QPs" << endl;
        return 1;
    }
    REMOTE_SHARED(tr1_c1, con);
    REMOTE_SHARED(tr1_c2, con);
    
    SILENT_SYNC("program start");
    
    //--------------------------------------------------------
    //-------------- Do something -----------------------------
    //$13 //incorporate test body client;
    c1 = X;
    c2 = X;
    //--------------------------------------------------------
    //-------------- End operations ---------------------------
    
    SILENT_SYNC("end of operations");
    //$15// incorporateTestCollate; sending local variables;
    Scrap = c1;
    POST_PUT(con,tcp_port,Scrap, tr1_c1);
    POLL_CQ(con,tcp_port);

    Scrap = c2;
    POST_PUT(con,tcp_port,Scrap, tr1_c2);
    POLL_CQ(con,tcp_port);

    cout << "X="<< X << "; c1="<< c1 << "; c2="<< c2 <<endl;
    cout << "ended test" << endl;  
    SILENT_SYNC("end of collecting results");
    SILENT_SYNC("end of validating results");
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
        rc = thr0();
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
/* //source ir
//$11;
*/