import asyncio
import functions
import yaml
import functions
import sys
from loguru import logger

# load example_tasks.yaml
def load_task(yaml_filename):
    with open(yaml_filename, 'r') as stream:
        try:
            content = yaml.safe_load(stream)
            global_config = content['global']
            tasks = content['tasks']
            print(yaml.dump(tasks, default_flow_style=False, sort_keys=False))
            return global_config, tasks
        except yaml.YAMLError as exc:
            logger.error(exc)
            return None

async def read_next(filename,lastseen=0):
  with open(filename) as fil:
    fil.seek(lastseen)
    # print(f'', 'SEEK: ', lastseen)
    await asyncio.sleep(0.8)
    log_line = fil.readline()
    if fil.tell() != lastseen:
        return log_line, fil.tell()
    else:
        return None, lastseen

async def task_process(log_filename, task, vars_dict, global_config):
    lastseen = 0
    timeout_seconds = -1
    start_time = 0
    current_name = task['name'] 
    current_workflow = task['workflow']
    log_line = ''
    try:
        current_environment = task['environment']
        logger.opt(colors=True).info(f'<yellow>{current_name:^30s}</yellow> TASK: {current_name}')
        for action in current_environment:
            action_type, arguments = list(action.items())[0]
            if action_type == 'set':
                var_name, var_value = arguments
                vars_dict[var_name] = var_value
                logger.opt(colors=True).info(f'<yellow>{current_name:^30s}</yellow> SET VARS: {vars_dict}')
    except KeyError:
        logger.opt(colors=True).info(f'<yellow>{current_name:^30s}</yellow> NO ENVIRONMENT OVERRIDE, SKIP.')
            
    for action in current_workflow:
        action_type, arguments = list(action.items())[0]
        logger.opt(colors=True).info(f'<yellow>{current_name:^30s}</yellow> ACTION: {action_type} with {arguments} as arguments')

        if action_type == 'call':
            functions.call(arguments)

        elif action_type == 'timeout':
            timeout_seconds = arguments
            if timeout_seconds != -1:
                start_time = asyncio.get_event_loop().time()

        elif action_type == 'capture':
            log_template = arguments
            capture_result = dict()
            while len(capture_result) == 0:
                # Check if timeout_seconds is set
                if timeout_seconds != -1:
                    elapsed_time = asyncio.get_event_loop().time() - start_time
                    if elapsed_time >= timeout_seconds:
                        logger.opt(colors=True).error(f'<yellow>{current_name:^30s}</yellow> TIMEOUT while handling CAPTURE with \'{log_template}\'',)
                        raise asyncio.TimeoutError

                log_line, lastseen = await read_next(log_filename, lastseen)
                if (log_line):
                    # logger.opt(colors=True).info(f'<yellow>{current_name:^30s}</yellow> {log_line.strip()}')
                    capture_result = functions.capture(log_line, log_template)
            vars_dict.update(capture_result)
            logger.opt(colors=True).info(f'<yellow>{current_name:^30s}</yellow> VARS: {vars_dict}')
        
        elif action_type == 'ensure':
            op, var_name, value = arguments
            res = functions.ensure(op, var_name, value, vars_dict)
            if res:
                logger.opt(colors=True).info(f'<yellow>{current_name:^30s}</yellow> ENSURE: {var_name} {op} {value} is True')
            else:
                logger.opt(colors=True).error(f'<yellow>{current_name:^30s}</yellow> ENSURE: {var_name} {op} {value} is False')
                if log_line:
                    logger.opt(colors=True).error(f'<yellow>{current_name:^30s}</yellow> Last processed log line: {log_line.strip()}')
                return
                
            
        elif action_type == 'require':
            op, var_name, value = arguments
            res = functions.require(op, var_name, value, global_config)
            if res:
                logger.opt(colors=True).info(f'<yellow>{current_name:^30s}</yellow> REQUIRE: {var_name} is {op} to {value}')
            else:
                logger.opt(colors=True).warning(f'<yellow>{current_name:^30s}</yellow> REQUIRE: {var_name} is not {op} to {value}')
                return

        else:
            logger.opt(colors=True).info(f'<yellow>{current_name:^30s}</yellow> ACTION: {action_type} is not supported')
            return
    logger.opt(colors=True).success(f'<yellow>{current_name:^30s}</yellow> Done.')

async def main():
    vars_dict = dict()
    content = load_task('example_tasks.yaml')
    filename = 'dummy_log.txt'

    if content is None:
        logger.opt(colors=True).info('Error loading tasks')
        return None
    global_config, tasks = content
    task_list = []

    for task_config in tasks:
        task_list.append(asyncio.create_task(task_process(filename, task_config, vars_dict, global_config)))

    try:
        await asyncio.gather(*task_list)
    except asyncio.TimeoutError:
        logger.opt(colors=True).critical(f'TIMEOUT')

if __name__ == "__main__":
    logger.remove()
    logger.add("file_{time}.log", rotation="500 MB", level="DEBUG")
    logger.add(
        sys.stderr,
        colorize=True,
        format="<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | <level>{level: ^8}</level> | <m>{file}</m>:<cyan>{line:04d}</cyan> - <level>{message}</level>",
        level="DEBUG",
    )
    asyncio.run(main())
