#include <iostream>
using std::cout;
using std::cerr;
using std::endl;
using std::ostream;

#include <thread>
//std::thread

#include <vector>
#include <string>
// //for include ..random
// #include <stdio.h>      /* printf, scanf, puts, NULL */
// #include <time.h>       /* time */
// //end of for include ..random and sleep(10)
#include <stdlib.h>     /* atoi */

#include <iostream> // for reading from a file
#include <fstream> // for reading from a file

#include "rdma_code/resources.h"
using rdma::Resources;

#include "rdma_code/connection.h"
using rdma::Connection;

#include "rdma_code/connection_manager.h"
using rdma::ConnectionManager;

#define SERVER_ID 0
#define PORT 19875
#define FILE_NAME "manual_attempt1.cpp"//$0;

std::vector<string> thr_ips;
std::vector<uint32_t> thr_ports;
char file_line_delim=' ';
/******************************************************************************************/
/******************************************************************************************/
/**                                                                                      **/
/**                 manual attempt before test templates creation                        **/
/**                                                                                      **/
/******************************************************************************************/
/******************************************************************************************/

#define LOCAL_SHARED(varName,con) \
        rdma::LocalConData<uint64_t>  varName##_res(#varName);\
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

#define CONNECT_QP(my_name) {\
        if (con.connectQP()){\
            cerr << my_name << " failed to connect QPs" << endl;\
            return 1;\
        }\
    }

int thr0(){//server(number_of_clients=1){
    int my_id=0;
    string whoami="thr"+my_id;
    //--------------------------------------------------------
    //-------------- Set up ----------------------------------
    int ret = 0;
     //$05 // incorporate local declaration;
    rdma::ConnectionManager con(SERVER_ID,  thr_ports[SERVER_ID]);
    //$03     // incorporate test init;
    LOCAL_SHARED(Y1, con) = 2;
    LOCAL_SHARED(Y2, con) = 1;

    LOCAL_SHARED(tr1_c1, con) = 0;
    LOCAL_SHARED(tr1_c2, con) = 0;

    
    /* connect the QPs */
    con.add_connection(1, thr_ips[1]);

    CONNECT_QP(whoami);

    cout << "connected to queue thr0" << endl;  
    //$10 //incorporate remotely accessed varaibles;
    REMOTE_SHARED(X, con.at(1));

    //$13 //incorporate test body;
    // --------------------------------------------------------
    // -------------- Do something -----------------------------
    SILENT_SYNC("program start");

    cout << "starting test" << endl;  

    try{
        POST_PUT(con.at(1),whoami,Y1, X);
        POST_PUT(con.at(1),whoami,Y2, X);
        POLL_CQ(con.at(1),whoami);
        POLL_CQ(con.at(1),whoami);
    }catch(std::exception &e){
        cerr << "Server failed because " << e.what() << endl;
        ret = 1;
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
    //$16
    cout << "Y1="<< Y1 << "; Y2="<< Y2 << endl;
    cout << "ended test" << endl;  
    SILENT_SYNC("end of validating results");
    return ret;
}



int thr1(){
    int my_id=1;
    string whoami="thr"+my_id;
    int ret = 0;
    //--------------------------------------------------------
    //-------------- Set up ----------------------------------
 
     //$5 // incorporate local declaration;
    uint64_t c1,c2;
    rdma::ConnectionManager con(my_id, thr_ports[my_id]);
    //$3   incorporateSharedVarDecls(os);
    LOCAL_SHARED(X, con) = 0;
    LOCAL_SHARED(Scrap, con) = 1;

    //$4   incorporateAddConnections(os);
    con.add_connection(0, thr_ips[0]);

    CONNECT_QP(whoami);
    //$10
    REMOTE_SHARED(tr1_c1, con.at(0));
    REMOTE_SHARED(tr1_c2, con.at(0));
    
    SILENT_SYNC("program start");
    
    //--------------------------------------------------------
    //-------------- Do something -----------------------------
    //$13 //incorporate test body client;

    try{
       c1 = X;
       c2 = X;
    }catch(std::exception &e){
        cerr << "Client failed because " << e.what() << endl;
        ret = 1;
    }    //--------------------------------------------------------
    //-------------- End operations ---------------------------
    
    sleep(10);
    SILENT_SYNC("end of operations");
    //$15// incorporateTestCollate; sending local variables;
    Scrap = c1;
    POST_PUT(con.at(0),whoami,Scrap, tr1_c1);
    POLL_CQ(con.at(0),whoami);

    Scrap = c2;
    POST_PUT(con.at(0),whoami,Scrap, tr1_c2);
    POLL_CQ(con.at(0),whoami);

    //$16
    cout << "X="<< X << "; c1="<< c1 << "; c2="<< c2 <<endl;
    cout << "ended test" << endl;  
    SILENT_SYNC("end of collecting results");
    SILENT_SYNC("end of validating results");
    return ret;

}

void parsePortsIpsFromLine(string line){
    string p_id_s;
    std::stringstream line_s(line);
    std::getline(line_s, p_id_s, file_line_delim);
    int p_id = atoi(p_id_s.c_str());
    string p_ip,p_port;
    std::getline(line_s, p_ip, file_line_delim);
    std::getline(line_s, p_port, file_line_delim);
    thr_ips[p_id] = p_ip;
    thr_ports[p_id] = atoi(p_port.c_str());
}

int parseInputFile(string filename, int expected_num_thrds){
    std::ifstream myfile(filename);
    int count_thrs=0;
    if (! myfile.is_open())  {
        cerr << "Failed opening file " << filename << endl;
        return 1;
    }//else

    string line;
    while ( getline (myfile,line) ){
        ++count_thrs;
        parsePortsIpsFromLine(line);
    }
    myfile.close();

    if(count_thrs != expected_num_thrds){
        cerr << "read file " << filename << " has " << count_thrs << "threads"
             << " while, " << expected_num_thrds << "threads were expected." << endl;
        return 1;
    }//else
    return 0;
}

int main (int argc, char *argv[])
{
    int expected_num_thrds = 2;

    if(argc < 3){
        cout << "Expected: " << argv[0]<< " <my_id> <filename of \"id ip port\" list>" 
             << endl;
        return 1;
    }
    
    int thr_id = atoi (argv[1]);
    string filename=argv[2];
    if(parseInputFile(filename, expected_num_thrds)){
        return 1;
    }
    rdma::Resources::initialize();

    int rc = 0;
    if (0==thr_id){
        rc = thr0();
        std::cout << "server thr";
    } else{
        rc = thr1();
        std::cout << "client";
    }

    // Destruction/cleanup phaze
    cout << " "<< thr_id << " ";
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