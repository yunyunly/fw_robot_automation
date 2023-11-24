
"""The Python implementation of the GRPC remote_worker.RemoteWorker server."""

from concurrent import futures
import logging

import grpc
import remote_worker_pb2
import remote_worker_pb2_grpc 

import subprocess 
import datetime

class RemoteWorker(remote_worker_pb2_grpc.RemoteWorkerServicer):
    def CommandLine(self, request, context):
        command = ""
        command += f"{request.cmd} " if request.cmd != "NULL" else ""
        command += f"{request.arg0} " if request.arg0 != "NULL" else ""
        command += f"{request.arg1} " if request.arg1 != "NULL" else ""
        command += f"{request.arg2} " if request.arg2 != "NULL" else ""
        command += f"{request.arg3} " if request.arg3 != "NULL" else ""
        command += f"{request.arg4} " if request.arg4 != "NULL" else ""
        command += f"{request.arg5} " if request.arg5 != "NULL" else ""
        command += f"{request.arg6} " if request.arg6 != "NULL" else ""
        command += f"{request.arg7} " if request.arg7 != "NULL" else ""
        command += f"{request.arg8} " if request.arg8 != "NULL" else ""
        command += f"{request.arg9} " if request.arg9 != "NULL" else ""
        command += f"{request.arg10} " if request.arg10 != "NULL" else ""
        command += f"{request.arg11} " if request.arg11 != "NULL" else ""
        command += f"{request.arg12} " if request.arg12 != "NULL" else ""
        
        print(f"================{datetime.datetime.now()}================")
        print("exec:", command)
        try:
            # Use subprocess to execute the CLI program and capture its output
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            # Read and yield the output in real-time as a stream to the client
            for line in process.stdout:
                response = remote_worker_pb2.CommandLineReply(stream=line, returncode=3026478)
                yield response

            process.wait()
            response = remote_worker_pb2.CommandLineReply(stream="end\n", returncode=process.returncode)
            yield response
            print("returncode:", process.returncode)
        except Exception as e:
            response = remote_worker_pb2.CommandLineReply(stream=f"Error: {str(e)}", returncode=-1)
            yield response

        # q = queue.Queue()
        # stream = program_pb2.ProgramReply()
        # output = subprocess.check_output(["ls","-la"])
        # output = output.decode("utf-8")
        # for i in range(3):
        #     response = program_pb2.ProgramReply(message=output)
        #     yield response


def serve():
    port = "50051"
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    remote_worker_pb2_grpc.add_RemoteWorkerServicer_to_server(RemoteWorker(), server)
    server.add_insecure_port("[::]:" + port)
    server.start()
    print("Server started, listening on " + port)
    server.wait_for_termination()


if __name__ == "__main__":
    logging.basicConfig()
    serve()
